
#[test_only]
module campaign::campaign_tests {
    // use std::debug::print;
    use sui::test_scenario::{Self};
    use sui::clock::{Self};

    use campaign::campaign::{Self as hd, AdminCap, CampaignOwnerCap, Campaign};

    // Test addresses.
    const ADMIN: address = @0xAAA;
    // const OWNER: address = @0xAAA;
    // const FIRST_OWNER: address = @0xCAFE;
    // const FINAL_OWNER: address = @0xFACE;
    const REFERRER_A: address = @0x1234;
    const REFERRER_B: address = @0x3456;
    const REFERRER_C: address = @0x5678;
    const COMMON_USER: address = @0x7890;

    #[test]
    fun test_init() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = scenario.ctx();
        hd::init_for_testing(ctx);
        scenario.end();
    }

    #[test]
    fun test_create_campaign() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = scenario.ctx();
        hd::init_for_testing(ctx);

        scenario.next_tx(ADMIN);
        {
            let admin_cap = scenario.take_from_sender<AdminCap>();
            let ctx = scenario.ctx();
            hd::create_campaign(&admin_cap, ctx);
            
            scenario.return_to_sender(admin_cap);
        };

        scenario.end();
    }

    #[test]
    fun test_create_referral() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = scenario.ctx();
        hd::init_for_testing(ctx);

        let mut clock = clock::create_for_testing(ctx);
        clock.increment_for_testing(1);
        clock.share_for_testing();

        scenario.next_tx(ADMIN);
        {
            let admin_cap = scenario.take_from_sender<AdminCap>();
            let ctx = scenario.ctx();
            hd::create_campaign(&admin_cap, ctx);
            
            scenario.return_to_sender(admin_cap);
        };

        scenario.next_tx(REFERRER_B);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::create_referral(&campaign_owner, &mut campaign, REFERRER_A, &clock, ctx);
                        
            // print(&campaign);

            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.next_tx(REFERRER_C);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::create_referral(&campaign_owner, &mut campaign, REFERRER_B, &clock, ctx);
                        
            // print(&campaign);

            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::campaign::campaign::EReferrerNotBeReferee)]
    fun test_create_referral_exist_referrer() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = scenario.ctx();
        hd::init_for_testing(ctx);

        let mut clock = clock::create_for_testing(ctx);
        clock.increment_for_testing(1);
        clock.share_for_testing();

        scenario.next_tx(ADMIN);
        {
            let admin_cap = scenario.take_from_sender<AdminCap>();
            let ctx = scenario.ctx();
            hd::create_campaign(&admin_cap, ctx);
            
            scenario.return_to_sender(admin_cap);
        };

        scenario.next_tx(REFERRER_B);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::create_referral(&campaign_owner, &mut campaign, REFERRER_A, &clock, ctx);
                        
            // print(&campaign);

            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.next_tx(REFERRER_C);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::create_referral(&campaign_owner, &mut campaign, REFERRER_B, &clock, ctx);
                        
            // print(&campaign);

            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.next_tx(REFERRER_A);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::create_referral(&campaign_owner, &mut campaign, REFERRER_C, &clock, ctx);
                        
            // print(&campaign);

            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::campaign::campaign::ERefereeExistAlready)]
    fun test_create_referral_exist_referee() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = scenario.ctx();
        hd::init_for_testing(ctx);

        let mut clock = clock::create_for_testing(ctx);
        clock.increment_for_testing(1);
        clock.share_for_testing();

        scenario.next_tx(ADMIN);
        {
            let admin_cap = scenario.take_from_sender<AdminCap>();
            let ctx = scenario.ctx();
            hd::create_campaign(&admin_cap, ctx);
            
            scenario.return_to_sender(admin_cap);
        };

        scenario.next_tx(REFERRER_B);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::create_referral(&campaign_owner, &mut campaign, REFERRER_A, &clock, ctx);
                        
            // print(&campaign);

            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.next_tx(REFERRER_B);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::create_referral(&campaign_owner, &mut campaign, REFERRER_C, &clock, ctx);
                        
            // print(&campaign);

            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }

    #[test]
    fun test_log_user_activity() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = scenario.ctx();
        hd::init_for_testing(ctx);

        let mut clock = clock::create_for_testing(ctx);
        clock.increment_for_testing(1);
        clock.share_for_testing();

        scenario.next_tx(ADMIN);
        {
            let admin_cap = scenario.take_from_sender<AdminCap>();
            let ctx = scenario.ctx();
            hd::create_campaign(&admin_cap, ctx);
            
            scenario.return_to_sender(admin_cap);
        };

        scenario.next_tx(COMMON_USER);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::log_user_activity(&campaign_owner, &mut campaign, &clock, ctx);
                        
            // print(&campaign);

            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }    
}

