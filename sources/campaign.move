/// Module: campaign
module campaign::campaign {
    use sui::event;
    use sui::clock::{Self, Clock};
    use std::string::String;
    use std::option::{none, some};

    /* Error Constants */
    const ECampaignEndedAlready: u64 = 5;
    const EAddressNotExist: u64 = 7;
    const EPermissionNotExist: u64 = 8;
    const ENotReferThemselves: u64 = 1;
    const EAlreadyReferrer: u64 = 2;
    const EAlreadyReferee: u64 = 3;
    const ENotAdmin: u64 = 100;

    /* Structs */

    public struct CAMPAIGN has drop {}

    // Admin capability struct
    public struct AdminCap has key, store {
        id: UID
    }

    // Main campaign object (mostly immutable, rarely mutated)
    public struct Campaign has key, store {
        id: UID,
        admin: address,
        title: String,
        about: String,
        active: bool,
        started_at: u64,
        ended_at: Option<u64>
    }

    // Per-user whitelist object (sharded user state)
    public struct UserWhitelist has key, store {
        id: UID,
        user: address,
        permission: bool,
        referees_count: u64,
        is_referee: bool
    }

    public struct ReferralEvent has copy, drop {
        referrer: address,
        referee: address,
        created_at: u64,
    }

    public struct LoginEvent has copy, drop {
        user: address,
        loggedin_at: u64,
    }

    // Module initializer
    fun init(_otw: CAMPAIGN, ctx: &mut TxContext) {
        let admin_cap = AdminCap { id: object::new(ctx) };
        // transfer::transfer(admin_cap, ctx.sender());
        transfer::share_object(admin_cap);
    }

    // Create a campaign (admin only)
    public entry fun create_campaign(
        _: &AdminCap,
        title: String,
        about: String,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let campaign_uid = object::new(ctx);
        let campaign = Campaign {
            id: campaign_uid,
            admin: ctx.sender(),
            title,
            about,
            active: true,
            started_at: clock::timestamp_ms(clock),
            ended_at: none()
        };
        transfer::share_object(campaign);
    }

    // End campaign (admin only)
    public entry fun end_campaign(
        _: &AdminCap,
        campaign: &mut Campaign,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Check if sender is admin
        assert!(campaign.admin == ctx.sender(), ENotAdmin);
        // Check if campaign is active
        assert!(campaign.active == true, ECampaignEndedAlready);

        campaign.active = false;
        campaign.ended_at = some(clock::timestamp_ms(clock));
    }

    // Delete campaign (admin only)
    public entry fun delete_campaign(
        _: &AdminCap,
        campaign: Campaign,
        ctx: &mut TxContext
    ) {
        // Check if sender is admin
        assert!(campaign.admin == ctx.sender(), ENotAdmin);
        
        let Campaign { id, .. } = campaign;
        object::delete(id);
        // Note: UserWhitelist objects must be deleted separately if desired.
    }

    // Add user to whitelist (admin only)
    public entry fun add_whitelist(
        campaign: &Campaign,
        user: address,
        permission: bool,
        ctx: &mut TxContext
    ) {
        assert!(campaign.admin == ctx.sender(), ENotAdmin);

        // Create a new UserWhitelist object for the user
        let user_whitelist = UserWhitelist {
            id: object::new(ctx),
            user,
            permission,
            referees_count: 0,
            is_referee: false
        };
        
        // transfer::transfer(user_whitelist, user);
        
        transfer::share_object(user_whitelist);
    }

    // Update permission for a user (admin only)
    public entry fun update_permission_whitelist(
        campaign: &Campaign,
        user_whitelist: &mut UserWhitelist,
        permission: bool,
        ctx: &mut TxContext
    ) {
        assert!(campaign.admin == ctx.sender(), ENotAdmin);

        user_whitelist.permission = permission;
    }

    // Remove a user from whitelist (admin only)
    public entry fun remove_whitelist(
        user_whitelist: UserWhitelist
    ) {
        let UserWhitelist { id, .. } = user_whitelist;
        object::delete(id);
    }

    // Batch remove users from whitelist (admin only)
    public entry fun batch_remove_whitelist(
        mut user_whitelists: vector<UserWhitelist>
    ) {
        // Pop and delete each UserWhitelist until the vector is empty
        while (!vector::is_empty(&user_whitelists)) {
            let user_whitelist = vector::pop_back(&mut user_whitelists);
            let UserWhitelist { id, .. } = user_whitelist;
            object::delete(id);
        };
        
        // At this point, user_whitelists is empty and can be dropped safely
        vector::destroy_empty(user_whitelists);
    }

    // User logs activity (user only)
    public entry fun log_user_activity(
        campaign: &Campaign,
        user_whitelist: &UserWhitelist,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(campaign.active == true, ECampaignEndedAlready);
        assert!(user_whitelist.permission == true, EPermissionNotExist);
        assert!(user_whitelist.user == ctx.sender(), EAddressNotExist);

        let current_time = clock::timestamp_ms(clock);
        event::emit(LoginEvent {
            user: user_whitelist.user,
            loggedin_at: current_time
        });
    }    

    // Create a referral (user only)
    public entry fun create_referral(
        campaign: &Campaign,
        referee_whitelist: &mut UserWhitelist,
        referrer_whitelist: &mut UserWhitelist,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(campaign.active == true, ECampaignEndedAlready);
        let referee = ctx.sender();

        // Check permissions
        assert!(referee_whitelist.user == referee, EAddressNotExist);
        assert!(referee_whitelist.permission == true, EPermissionNotExist);
        assert!(referrer_whitelist.permission == true, EPermissionNotExist);

        // Cannot refer themselves
        assert!(referee != referrer_whitelist.user, ENotReferThemselves);

        // Check if referee is already a referrer
        assert!(referee_whitelist.referees_count == 0, EAlreadyReferrer);
        // Check if referee is already a referee
        assert!(referee_whitelist.is_referee == false, EAlreadyReferee);

        // Register referee as referred
        referee_whitelist.is_referee = true;

        // Increment referrer's count
        referrer_whitelist.referees_count = referrer_whitelist.referees_count + 1;

        let created_at = clock::timestamp_ms(clock);
        event::emit(ReferralEvent {
            referrer: referrer_whitelist.user,
            referee,
            created_at
        });
    }

    // Helper: Only for testing, create admin cap
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        let admin_cap = AdminCap { id: object::new(ctx) };
        transfer::transfer(admin_cap, ctx.sender());
    }

    /*
    //  Batch add users to whitelist (admin only)
    public entry fun batch_add_whitelist(
        campaign: &Campaign,
        mut users: vector<address>,
        ctx: &mut TxContext
    ) {
        assert!(campaign.admin == ctx.sender(), ENotAdmin);

        while (!vector::is_empty(&users)) {
            let user = vector::pop_back(&mut users);
            let user_whitelist = UserWhitelist {
                id: object::new(ctx),
                user,
                permission: true,
                referees_count: 0,
                is_referee: false
            };
            transfer::share_object(user_whitelist);
        };

        // At this point, users is empty and can be dropped safely
        vector::destroy_empty(users);
    }
*/
}