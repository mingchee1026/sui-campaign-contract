/// Module: campaign
module campaign::campaign {
    // imports
    // use std::vector;
    // use sui::transfer;
    // use sui::tx_context::{Self, TxContext};
    // use sui::object::{Self, UID};
    // use sui::clock::{Self, Clock};

    use sui::event;
    use sui::clock::{Self, Clock};

    /* Error Constants */
    const ENotReferThemselves: u64 = 0;
    const EReferralExistAlready: u64 = 1;
    
    // struct definitions

    // admin capability struct
    public struct AdminCap has key, store {
        id: UID
    }
    
    public struct Campaign has key, store {
        id: UID,
        referrals: vector<Referral>,
        activities: vector<Activity>,
    }

    public struct Referral has key, store {
        id: UID,
        referrer: address,
        referee: address,
        created_at: u64,
    }

    public struct ReferralDetails has copy, drop {
        referrer: address,
        referee: address,
        created_at: u64,
    }

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

    public struct ActivityDetails has copy, drop {
        user: address,
        loggedin_at: u64,
    }

    public struct LoginEvent has copy, drop {
        user: address,
        loggedin_at: u64,
    }

    // Module initializer to be executed when this module is published
    fun init(ctx: &mut TxContext) {
        // let admin_address = tx_context::sender(ctx);

        // Creating and sending the AdminCap object to the sender.
        let admin_cap = AdminCap {
            id: object::new(ctx)
        };

        let new_campaign = Campaign {
            id: object::new(ctx),
            referrals: vector::empty<Referral>(),
            activities: vector::empty<Activity>(),
        };

        transfer::share_object(new_campaign);

        transfer::transfer(admin_cap, ctx.sender()); //, admin_address);
    }

    // create a campaign
    // this function uses the capability design pattern (admin_cap) to ensure that only
    // an admin can create campaign
    public entry fun create_campaign(_: &AdminCap, ctx: &mut TxContext) {
        let campaign_uid = object::new(ctx);

        let campaign = Campaign {
            id: campaign_uid,
            referrals: vector::empty<Referral>(),
            activities: vector::empty<Activity>(),
        };

        transfer::share_object(campaign);
    }

    // Create a new referral
    public entry fun create_referral(
        campaign: &mut Campaign,
        referee: address,
        clock: &Clock,
        ctx: &mut TxContext) {
        let referrer = ctx.sender(); //tx_context::sender(ctx);

        assert!(referee != referrer, ENotReferThemselves);

        // Check if the referral exists
        let exist = campaign.referral_exist(referrer, referee);

        assert!(!exist, EReferralExistAlready);

        let referral_uid = object::new(ctx);
        let created_at = clock::timestamp_ms(clock);

        // Create a new referral
        let new_referral = Referral {
            id: referral_uid,
            referrer,
            referee,
            created_at: created_at
        };

        // Add the new referral to the vector
        vector::push_back(&mut campaign.referrals, new_referral);

        // Emit the referral event
        event::emit(ReferralEvent {
            referrer,
            referee,
            created_at
        });
    }

    // Retrieve the referrer’s address given a UID
    // public fun get_referrer(campaign: &Campaign, uid: u64): address {
    //     let referral = vector::borrow(&campaign.referrals, uid);
    //     let referrer = referral.referrer;
        
    //     referrer;
    // }

    // Retrieve the referee’s address given a UID
    // public fun get_referee(campaign: &Campaign, uid: u64): address {
    //     let referral = vector::get(&campaign.referrals, uid);
    //     return referral.referee;
    // }

    // Log user activity
    public entry fun log_user_activity(
        campaign: &mut Campaign,
        clock: &Clock,
        ctx: &mut TxContext) {
        let user = ctx.sender(); //tx_context::sender(ctx);
        
        // Retrieve the current on-chain time
        let current_time = clock::timestamp_ms(clock);

        let new_activity = Activity {
            id: object::new(ctx),
            user: user,
            loggedin_at: clock::timestamp_ms(clock)
        };
        
        // Add the new activity to the vector
        vector::push_back(&mut campaign.activities, new_activity);

        // Emit user activity event
        event::emit(LoginEvent {
            user: user, 
            loggedin_at: current_time
        });
    }

    // Get all referrals
    public entry fun get_all_referrals(campaign: &Campaign): vector<ReferralDetails> {
        let mut all_referrals: vector<ReferralDetails> = vector::empty<ReferralDetails>();

        let len = vector::length(&campaign.referrals);

        let mut i = 0;

        // Iterate through all referrals and create ReferralDetails
        while (i < len) {
            let referral = vector::borrow(&campaign.referrals, i);
            let details = ReferralDetails {
                referrer: referral.referrer,
                referee: referral.referee,
                created_at: referral.created_at
            };

            vector::push_back(&mut all_referrals, details);

            i = i + 1;
        };

        all_referrals
    }

    // Get all referees given a referrer
    public entry fun get_referees_by_referrer(
        campaign: &Campaign,
        referrer: address): vector<address> {
        let mut referees: vector<address> = vector::empty<address>();

        let len = vector::length(&campaign.referrals);

        let mut i = 0;

        // Iterate through all referrals and collect referees for the given referrer
        while (i < len) {
            let referral = vector::borrow(&campaign.referrals, i);
            if (referral.referrer == referrer) {
                vector::push_back(&mut referees, referral.referee);
            };

            i = i + 1;
        };

        referees
    }

    // Get all referrers given a referee
    public entry fun get_referrers_by_referee(
        campaign: &Campaign,
        referee: address): vector<address> {
        let mut referrers: vector<address> = vector::empty<address>();

        let len = vector::length(&campaign.referrals);

        let mut i = 0;

        // Iterate through all referrals and collect referrers for the given referee
        while (i < len) {
            let referral = vector::borrow(&campaign.referrals, i);
            if (referral.referee == referee) {
                vector::push_back(&mut referrers, referral.referrer);
            };

            i = i + 1;
        };

        referrers
    }

    // Get all activities
    public entry fun get_all_activities(campaign: &Campaign): vector<ActivityDetails> {
        let mut all_activities: vector<ActivityDetails> = vector::empty<ActivityDetails>();

        let len = vector::length(&campaign.activities);

        let mut i = 0;

        // Iterate through all referrals and create ActivityDetails
        while (i < len) {
            let activity = vector::borrow(&campaign.activities, i);
            let details = ActivityDetails {
                user: activity.user,
                loggedin_at: activity.loggedin_at,
            };

            vector::push_back(&mut all_activities, details);

            i = i + 1;
        };

        all_activities
    }

    // Private Functions

    // Check if a referral exists given a referrer and referee
    fun referral_exist(
        campaign: &Campaign, 
        referrer: address, 
        referee: address): bool {
        let mut exist: bool = false;

        let len = vector::length(&campaign.referrals);

        let mut i = 0;

        // Iterate through all referrals to check for existence
        while (i < len) {
            let referral = vector::borrow(&campaign.referrals, i);
            if (referral.referrer == referrer && referral.referee == referee) {
                exist = true; // Referral exists
            };

            i = i + 1;
        };
        
        exist
    }

    // Test Functions

    #[test_only]
    // Wrapper of module initializer for testing
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}

