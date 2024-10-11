
#[test_only]
module campaign::campaign_tests {
    use std::debug::print;
    use sui::test_scenario::{Self, Scenario};
    use sui::clock::{Self, Clock};

    use campaign::campaign::{Self as hd, AdminCap, Campaign};

    // Test addresses.
    const ADMIN: address = @0xAAA;
    const OWNER: address = @0xAAA;
    const FIRST_OWNER: address = @0xCAFE;
    const FINAL_OWNER: address = @0xFACE;
    const TEST_REFERRER: address = @0x1234;
    const TEST_REFEREE: address = @0x5678;

    public fun init_campaign(scenario: &mut Scenario, admin: address) {
        scenario.next_tx(admin);
        {
            let ctx = scenario.ctx();
            hd::init_for_testing(ctx);
        };

        // scenario.next_tx(admin);
        // {
        //     let admin_cap = scenario.take_from_sender<AdminCap>();

        //     print(&admin_cap);

        //     transfer::public_transfer(admin_cap, FIRST_OWNER);
        // };

        // scenario.next_tx(admin);
        // {
        //     let new_campaign = scenario.take_from_sender<Campaign>();

        //     print(&new_campaign);

        //     transfer::public_transfer(new_campaign, FINAL_OWNER);
        // };

        // scenario.next_tx(admin);
        // {
        //     let admin_cap = scenario.take_from_sender<AdminCap>();
        //     let ctx = scenario.ctx();

        //     admin_cap.create_campaign(ctx);

        //     transfer::public_transfer(admin_cap, FINAL_OWNER);
        // };
    }

    // #[test]
    // fun test_create_campaign() {
    //     let mut scenario = test_scenario::begin(ADMIN);
    //     {
    //         init_campaign(&mut scenario, ADMIN);
    //     };        

    //     scenario.next_tx(ADMIN);
    //     {
    //         let new_campaign = scenario.take_shared<Campaign>();

    //         print(&new_campaign);
            
    //         test_scenario::return_shared(new_campaign);
    //     };

    //     scenario.end();
    // }

    // #[test]
    // fun test_create_referral() {
    //     let mut scenario = test_scenario::begin(ADMIN);
    //     {
    //         let ctx = scenario.ctx();
    //         let mut clock = clock::create_for_testing(ctx);
    //         clock.increment_for_testing(1);
    //         clock.share_for_testing();

    //         init_campaign(&mut scenario, ADMIN);
    //     };        

    //     scenario.next_tx(TEST_REFEREE);
    //     {
    //         let mut origin_campaign = scenario.take_shared<Campaign>();
    //         let clock = scenario.take_shared<clock::Clock>();
    //         let ctx = scenario.ctx();

    //         origin_campaign.create_referral(OWNER, FIRST_OWNER, &clock, ctx);

    //         print(&origin_campaign);
            
    //         test_scenario::return_shared(clock);
    //         test_scenario::return_shared(origin_campaign);
    //     };

    //     scenario.end();
    // }

    #[test]
    fun test_log_user_activity() {
        let mut scenario = test_scenario::begin(ADMIN);
        {
            let ctx = scenario.ctx();
            let mut clock = clock::create_for_testing(ctx);
            clock.increment_for_testing(1);
            clock.share_for_testing();

            init_campaign(&mut scenario, ADMIN);
        };

        scenario.next_tx(FIRST_OWNER);
        {
            let mut origin_campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            origin_campaign.log_user_activity(OWNER, &clock, ctx);

            print(&origin_campaign);

            test_scenario::return_shared(clock);
            test_scenario::return_shared(origin_campaign);
        };

        scenario.end();
    }
    
}

