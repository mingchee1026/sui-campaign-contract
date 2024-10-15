/// Module: campaign
module campaign::campaign {
    use sui::event;
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    use sui::table_vec::{Self, TableVec};
    use sui::object_table::{Self, ObjectTable};

    /* Error Constants */
    const ENotCampaignOwner: u64 = 0;
    const ENotReferThemselves: u64 = 1;
    const EReferralExistAlready: u64 = 2;
    const EReferrerNotBeReferee: u64 = 3;
    const ERefereeExistAlready: u64 = 4;
    
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
    
    public struct Campaign has key, store {
        id: UID,
        total_referees: Table<address, address>,
        referrals: Table<address, TableVec<address>>,
        activities: ObjectTable<ID, Activity>,
    }

    // public struct Referral has key, store {
    //     id: UID,
    //     referrer: address,
    //     referee: address,
    //     created_at: u64,
    // }

    public struct ReferralEvent has copy, drop {
        referrer: address,
        referee: address,
        created_at: u64,
    }

    public struct Activity has key, store {
        id: UID,
        user: address,
        loggedin_at: u64,
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
    public entry fun create_campaign(_: &AdminCap, ctx: &mut TxContext) {
        let campaign_uid = object::new(ctx);
        let campaign_id = object::uid_to_inner(&campaign_uid);

        let campaign = Campaign {
            id: campaign_uid,
            total_referees: table::new<address, address>(ctx),
            referrals: table::new<address, TableVec<address>>(ctx),
            activities: object_table::new<ID, Activity>(ctx),
        };

        let campaign_owner_id = object::new(ctx);

        let campaign_owner = CampaignOwnerCap {
            id: campaign_owner_id,
            campaign_id
        };

        transfer::share_object(campaign);
        transfer::share_object(campaign_owner);
    }

    // Create a new referral
    public entry fun create_referral(
        cap: &CampaignOwnerCap,
        campaign: &mut Campaign,
        referrer: address,
        clock: &Clock,
        ctx: &mut TxContext) {
        let referee = ctx.sender();

        // asserts that the campaign from actually belongs to the caller
        assert!(cap.campaign_id == object::uid_to_inner(&campaign.id), ENotCampaignOwner);

        assert!(referee != referrer, ENotReferThemselves);

        // Check if referee is already registered as referrer
        let existReferrer = table::contains<address, TableVec<address>>(&campaign.referrals, referee);
        assert!(!existReferrer, EReferrerNotBeReferee);

        // Check if referee is already registered as referee
        assert!(!table::contains<address, address>(&campaign.total_referees, referee), ERefereeExistAlready);
        
        if (!table::contains<address, TableVec<address>>(&campaign.referrals, referrer)) {
            let mut referees = table_vec::empty<address>(ctx);
            table_vec::push_back(&mut referees, referee);
            table::add(&mut campaign.referrals, referrer, referees);

            // Add referee to the referees table
            table::add(&mut campaign.total_referees, referee, referee);
        }
        else {
            let referees = table::borrow_mut(&mut campaign.referrals, referrer);

            let mut exist: bool = false;
            let len = table_vec::length(referees);
            let mut i = 0;

            // Iterate through all referrals to check for existence
            while (i < len) {
                let added_referee = table_vec::borrow(referees, i);
                if (added_referee == referee) {
                    exist = true; // Referral exists
                    break
                };

                i = i + 1;
            };

            assert!(!exist, EReferralExistAlready);

            table_vec::push_back(referees, referee);

            // Add referee to the referees table
            table::add(&mut campaign.total_referees, referee, referee);
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

    // Log user activity
    public entry fun log_user_activity(        
        cap: &CampaignOwnerCap,
        campaign: &mut Campaign,
        clock: &Clock,
        ctx: &mut TxContext) {
        let user = ctx.sender(); //tx_context::sender(ctx);
        
        // asserts that the campaign from actually belongs to the caller
        assert!(cap.campaign_id == object::uid_to_inner(&campaign.id), ENotCampaignOwner);

        let activity_uid = object::new(ctx);
        let activity_key = activity_uid.to_inner();

        // Retrieve the current on-chain time
        let current_time = clock::timestamp_ms(clock);

        let new_activity = Activity {
            id: activity_uid,
            user: user,
            loggedin_at: clock::timestamp_ms(clock)
        };
        
        // Add the new activity to the table
        object_table::add(&mut campaign.activities, activity_key, new_activity);

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

