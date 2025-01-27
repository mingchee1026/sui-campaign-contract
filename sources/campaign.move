/// Module: campaign
module campaign::campaign {
    use sui::event;
    use std::string::String;
    use std::option::{none, some};
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};

    /* Error Constants */
    const ENotCampaignOwner: u64 = 0;
    const ENotReferThemselves: u64 = 1;
    const EReferralExistAlready: u64 = 2;
    const EReferrerNotBeReferee: u64 = 3;
    const ERefereeExistAlready: u64 = 4;
    const ECampaignEndedAlready:u64 = 5;
    const EAddressExistAlready: u64 = 6;
    const EAddressNotExist: u64 = 7;
    const EPermissionNotExist: u64 = 8;
    
    /* Structs */

    public struct CAMPAIGN has drop {}

    // admin capability struct
    public struct AdminCap has key, store {
        id: UID
    }

    // campaign owner cap  struct
    public struct CampaignOwnerCap has key, store {
        id: UID,
        campaign_id: ID
    }

    public struct ReferralItem has copy, drop, store  {
        referrer: address,
        referee: address
    }
    
    public struct Campaign has key, store {
        id: UID,
        title: String,
        about: String, // a breif description of the campaign
        active: bool,
        whitelist: Table<address, bool>,
        total_referees: Table<address, bool>,
        referrals: Table<address, Table<address, bool>>,
        testreferrals: Table<ReferralItem, u64>,
        activities: Table<address, Table<u64, bool>>,
        started_at: u64,
        ended_at: Option<u64>
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

    // Module initializer to be executed when this module is published
    fun init(_otw: CAMPAIGN, ctx: &mut TxContext) {
        // Creating and sending the AdminCap object to the sender.
        let admin_cap = AdminCap {
            id: object::new(ctx)
        };

        transfer::transfer(admin_cap, ctx.sender());
    }

    // create a campaign (and the owner object)
    // this function uses the capability design pattern (admin_cap) to ensure that only
    // an admin can create campaign
    public entry fun create_campaign(
        _: &AdminCap,
        title: String,
        about: String,
        clock: &Clock,
        ctx: &mut TxContext) {
        let campaign_uid = object::new(ctx);
        let campaign_id = object::uid_to_inner(&campaign_uid);

        let campaign = Campaign {
            id: campaign_uid,
            title,
            about,
            active: true,
            whitelist: table::new<address, bool>(ctx),
            total_referees: table::new<address, bool>(ctx),
            referrals: table::new<address, Table<address, bool>>(ctx),
            // testreferrals: table::new<address, address>(ctx),
            testreferrals: table::new<ReferralItem, u64>(ctx),
            activities: table::new<address, Table<u64, bool>>(ctx),
            started_at: clock::timestamp_ms(clock),
            ended_at: none()
        };

        let campaign_owner_id = object::new(ctx);

        let campaign_owner = CampaignOwnerCap {
            id: campaign_owner_id,
            campaign_id
        };

        transfer::share_object(campaign);
        transfer::share_object(campaign_owner);
    }

    // End campaign
    // this function uses the capability design pattern (admin_cap) to ensure that only
    // an admin can end campaign
    public entry fun end_campaign(_: &AdminCap, campaign: &mut Campaign, clock: &Clock) {
        // asserts that the campaign is not ended already before attempting to end it
        assert!(campaign.active == true, ECampaignEndedAlready);

        campaign.active = false;
        campaign.ended_at = some(clock::timestamp_ms(clock));
    }

    // Add custodial wallet address to whitelist
    // this function uses the capability design pattern (admin_cap) to ensure that only
    // an admin can add address
    public entry fun add_whitelist(
        _: &AdminCap, 
        campaign: &mut Campaign, 
        wallet_address: address,
        permission: bool) {
        // Check if address is already whitelisted
        // assert!(!table::contains<address, bool>(&campaign.whitelist, wallet_address), EAddressExistAlready);
        
        // Add address to the whitelist table
        if (!table::contains<address, bool>(&campaign.whitelist, wallet_address)) {
            table::add(&mut campaign.whitelist, wallet_address, permission);
        }
    }

    // Update permission of custodial wallet address in whitelist
    // this function uses the capability design pattern (admin_cap) to ensure that only
    // an admin can update permission
    public entry fun update_permission_whitelist(
        _: &AdminCap, 
        campaign: &mut Campaign, 
        wallet_address: address,
        permission: bool) {
        // Check if address is already whitelisted
        assert!(table::contains<address, bool>(&campaign.whitelist, wallet_address), EAddressNotExist);
        
        // Update permission of wallet address
        let old_permission = table::borrow_mut(&mut campaign.whitelist, wallet_address);
        *old_permission = permission;
    }

    // Create a new referral
    // The DApp will create the whitelist entry into the contract after a referral is created successfully.
    public entry fun create_referral(
        cap: &CampaignOwnerCap,
        campaign: &mut Campaign,
        referrer: address,
        clock: &Clock,
        ctx: &mut TxContext) {
        // asserts that the campaign is still ongoing before attempting to create referral
        assert!(campaign.active == true, ECampaignEndedAlready);

        let referee = ctx.sender();

        // asserts that the campaign from actually belongs to the caller
        assert!(cap.campaign_id == object::uid_to_inner(&campaign.id), ENotCampaignOwner);

        // Check if address is whitelisted
        // assert!(table::contains<address, bool>(&campaign.whitelist, referee), EPermissionNotExist);

        // Check if address has permission
        // let permission = table::borrow(&campaign.whitelist, referee);
        // assert!(permission == true, EPermissionNotExist);

        // Can not refer to itself
        // assert!(referee != referrer, ENotReferThemselves);

        // Check if referee is already registered as referrer
        // let existReferrer = table::contains<address, Table<address, bool>>(&campaign.referrals, referee);
        // assert!(!existReferrer, EReferrerNotBeReferee);

        // Check if referee is already registered as referee
        // assert!(!table::contains<address, bool>(&campaign.total_referees, referee), ERefereeExistAlready);
        
        if (!table::contains<address, Table<address, bool>>(&campaign.referrals, referrer)) {
            let mut referees = table::new<address, bool>(ctx);
            table::add(&mut referees, referee, true);
            table::add(&mut campaign.referrals, referrer, referees);

            // Add referee to the referees table
            // table::add(&mut campaign.total_referees, referee, true);
        }
        else {
            let referees = table::borrow_mut(&mut campaign.referrals, referrer);

            // Check if referee is already registered as referee
            assert!(!table::contains<address, bool>(referees, referee), EReferralExistAlready);

            table::add(referees, referee, true);

            // Add referee to the referees table
            // table::add(&mut campaign.total_referees, referee, true);
        };

        // Retrieve the current on-chain time
        let created_at = clock::timestamp_ms(clock);

        // Emit the referral event
        event::emit(ReferralEvent {
            referrer,
            referee,
            created_at
        });
    }

    public entry fun create_referral_test(
        cap: &CampaignOwnerCap,
        campaign: &mut Campaign,
        referrer: address,
        clock: &Clock,
        ctx: &mut TxContext) {
        // asserts that the campaign is still ongoing before attempting to create referral
        assert!(campaign.active == true, ECampaignEndedAlready);

        let referee = ctx.sender();

        // asserts that the campaign from actually belongs to the caller
        assert!(cap.campaign_id == object::uid_to_inner(&campaign.id), ENotCampaignOwner);

        // Check if address is whitelisted
        // assert!(table::contains<address, bool>(&campaign.whitelist, referee), EPermissionNotExist);

        // Check if address has permission
        // let permission = table::borrow(&campaign.whitelist, referee);
        // assert!(permission == true, EPermissionNotExist);

        // Can not refer to itself
        // assert!(referee != referrer, ENotReferThemselves);

        // Check if referee is already registered as referrer
        // let existReferrer = table::contains<address, Table<address, bool>>(&campaign.referrals, referee);
        // assert!(!existReferrer, EReferrerNotBeReferee);

        // Check if referee is already registered as referee
        // assert!(!table::contains<address, bool>(&campaign.total_referees, referee), ERefereeExistAlready);
        
        let item = ReferralItem{ referrer, referee };
        assert!(table::contains(&campaign.testreferrals, item) == false, ERefereeExistAlready);

        let current_time = clock::timestamp_ms(clock);

        // table::add(&mut campaign.testreferrals, referrer, referee);
        table::add(&mut campaign.testreferrals, item, current_time);
/*
        if (!table::contains<address, Table<address, bool>>(&campaign.referrals, referrer)) {
            let mut referees = table::new<address, bool>(ctx);
            table::add(&mut referees, referee, true);
            table::add(&mut campaign.referrals, referrer, referees);

            // Add referee to the referees table
            table::add(&mut campaign.total_referees, referee, true);
        }
        else {
            let referees = table::borrow_mut(&mut campaign.referrals, referrer);

            // Check if referee is already registered as referee
            assert!(!table::contains<address, bool>(referees, referee), EReferralExistAlready);

            table::add(referees, referee, true);

            // Add referee to the referees table
            table::add(&mut campaign.total_referees, referee, true);
        };
*/
        // Retrieve the current on-chain time
        let created_at = clock::timestamp_ms(clock);

        // Emit the referral event
        event::emit(ReferralEvent {
            referrer,
            referee,
            created_at
        });
    }

    // Log user activity
    public entry fun log_user_activity( 
        cap: &CampaignOwnerCap,       
        campaign: &mut Campaign,
        clock: &Clock,
        ctx: &mut TxContext) {
        // asserts that the campaign from actually belongs to the caller
        assert!(cap.campaign_id == object::uid_to_inner(&campaign.id), ENotCampaignOwner);

        // asserts that the campaign is still ongoing before attempting to create referral
        assert!(campaign.active == true, ECampaignEndedAlready);

        let user = ctx.sender();

        // Check if address is whitelisted
        assert!(table::contains<address, bool>(&campaign.whitelist, user), EPermissionNotExist);

        // Check if address has permission
        let permission = table::borrow(&campaign.whitelist, user);
        assert!(permission == true, EPermissionNotExist);

        // Retrieve the current on-chain time
        let current_time = clock::timestamp_ms(clock);
        
        if (!table::contains<address, Table<u64, bool>>(&campaign.activities, user)) {
            // Create new user's activities
            let mut activities = table::new<u64, bool>(ctx);
            // Add the new activity to the user's activities
            table::add(&mut activities, current_time, true);
            
            // Add the new user and activities to the table
            table::add(&mut campaign.activities, user, activities);
        }
        else {
            // Get user's activities
            let activities = table::borrow_mut(&mut campaign.activities, user);
            // Add the new activity to the user's activities
            table::add(activities, current_time, true);
        };        

        // Emit user activity event
        event::emit(LoginEvent {
            user: user, 
            loggedin_at: current_time
        });
    }

    /* Private Functions */

    

    /* Test Functions */

    #[test_only]
    // Wrapper of module initializer for testing
    public fun init_for_testing(ctx: &mut TxContext) {
        // Creating and sending the AdminCap object to the sender.
        let admin_cap = AdminCap {
            id: object::new(ctx)
        };

        transfer::transfer(admin_cap, ctx.sender());
    }
}

