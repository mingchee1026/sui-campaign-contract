
#[test_only]
module campaign::campaign_tests {
    // use std::debug::print;
    use sui::test_scenario::{Self};
    use std::string;
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

    fun create_campaign() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = scenario.ctx();
        hd::init_for_testing(ctx);

        let mut clock = clock::create_for_testing(ctx);
        clock.increment_for_testing(1);
        clock.share_for_testing();

        scenario.next_tx(ADMIN);
        {
            let admin_cap = scenario.take_from_sender<AdminCap>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();
            
            let title: vector<u8> = b"First Campaign";
            let about: vector<u8> = b"First Campaign";

            hd::create_campaign(&admin_cap, string::utf8(title), string::utf8(about), &clock, ctx);
            
            test_scenario::return_shared(clock);
            scenario.return_to_sender(admin_cap);
        };

        scenario.end();
    }

    fun end_campaign() {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            let admin_cap = scenario.take_from_sender<AdminCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();

            hd::end_campaign(&admin_cap, &mut campaign, &clock);
            
            test_scenario::return_shared(clock);
            scenario.return_to_sender(admin_cap);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }

    fun add_whitelist(wallet_address: address, permission: bool) {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            let admin_cap = scenario.take_from_sender<AdminCap>();
            let mut campaign = scenario.take_shared<Campaign>();

            hd::add_whitelist(&admin_cap, &mut campaign, wallet_address, permission);
            
            scenario.return_to_sender(admin_cap);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }

    #[test]
    fun test_init() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = scenario.ctx();
        hd::init_for_testing(ctx);
        scenario.end();
    }

    #[test]
    fun test_create_campaign() {
        create_campaign();
    }    

    #[test]
    fun test_end_campaign() {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            let ctx = scenario.ctx();
            let mut clock = clock::create_for_testing(ctx);
            clock.increment_for_testing(1);
            clock.share_for_testing();

            create_campaign();
        };

        scenario.next_tx(ADMIN);
        {
            end_campaign();
        };

        scenario.end();
    }

    #[test]
    fun test_add_whitelist() {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            create_campaign();
        };

        scenario.next_tx(ADMIN);
        {
            add_whitelist(ADMIN, true);
            add_whitelist(REFERRER_A, true);
            add_whitelist(REFERRER_B, true);
            add_whitelist(REFERRER_C, true);
            add_whitelist(COMMON_USER, true);
        };

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::campaign::campaign::EAddressExistAlready)]
    fun test_add_whitelist_duplicate() {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            create_campaign();
        };

        scenario.next_tx(ADMIN);
        {
            add_whitelist(ADMIN, true);
            add_whitelist(ADMIN, true);
        };

        scenario.end();
    }

    #[test]
    fun test_update_permission_whitelist() {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            create_campaign();
        };

        scenario.next_tx(ADMIN);
        {
            add_whitelist(REFERRER_A, true);
        };

        scenario.next_tx(ADMIN);
        {
            let admin_cap = scenario.take_from_sender<AdminCap>();
            let mut campaign = scenario.take_shared<Campaign>();

            hd::update_permission_whitelist(&admin_cap, &mut campaign, REFERRER_A, false);
            
            scenario.return_to_sender(admin_cap);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::campaign::campaign::EAddressNotExist)]
    fun test_update_permission_whitelist_no_exist_address() {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            create_campaign();
        };

        scenario.next_tx(ADMIN);
        {
            let admin_cap = scenario.take_from_sender<AdminCap>();
            let mut campaign = scenario.take_shared<Campaign>();

            hd::update_permission_whitelist(&admin_cap, &mut campaign, REFERRER_A, false);
            
            scenario.return_to_sender(admin_cap);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }

    #[test]
    fun test_create_referral() {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            let ctx = scenario.ctx();
            let mut clock = clock::create_for_testing(ctx);
            clock.increment_for_testing(1);
            clock.share_for_testing();

            create_campaign();
        };

        scenario.next_tx(ADMIN);
        {
            add_whitelist(REFERRER_B, true);
        };

        scenario.next_tx(REFERRER_B);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::create_referral(&campaign_owner, &mut campaign, REFERRER_A, &clock, ctx);
                        
            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::campaign::campaign::ECampaignEndedAlready)]
    fun test_create_referral_ended() {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            let ctx = scenario.ctx();
            let mut clock = clock::create_for_testing(ctx);
            clock.increment_for_testing(1);
            clock.share_for_testing();

            create_campaign();
        };

        scenario.next_tx(ADMIN);
        {
            end_campaign();
        };

        scenario.next_tx(ADMIN);
        {
            add_whitelist(REFERRER_B, true);
        };

        scenario.next_tx(REFERRER_B);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::create_referral(&campaign_owner, &mut campaign, REFERRER_A, &clock, ctx);
                        
            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::campaign::campaign::EPermissionNotExist)]
    fun test_create_referral_no_exist_address() {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            let ctx = scenario.ctx();
            let mut clock = clock::create_for_testing(ctx);
            clock.increment_for_testing(1);
            clock.share_for_testing();

            create_campaign();
        };

        scenario.next_tx(REFERRER_B);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::create_referral(&campaign_owner, &mut campaign, REFERRER_A, &clock, ctx);
                        
            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::campaign::campaign::EPermissionNotExist)]
    fun test_create_referral_no_permission() {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            let ctx = scenario.ctx();
            let mut clock = clock::create_for_testing(ctx);
            clock.increment_for_testing(1);
            clock.share_for_testing();

            create_campaign();
        };

        scenario.next_tx(ADMIN);
        {
            add_whitelist(REFERRER_B, false);
        };

        scenario.next_tx(REFERRER_B);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::create_referral(&campaign_owner, &mut campaign, REFERRER_A, &clock, ctx);
                        
            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::campaign::campaign::EReferrerNotBeReferee)]
    fun test_create_referral_exist_referrer() {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            let ctx = scenario.ctx();
            let mut clock = clock::create_for_testing(ctx);
            clock.increment_for_testing(1);
            clock.share_for_testing();

            create_campaign();
        };

        scenario.next_tx(ADMIN);
        {
            add_whitelist(REFERRER_A, true);
            add_whitelist(REFERRER_B, true);
            add_whitelist(REFERRER_C, true);
        };

        scenario.next_tx(REFERRER_B);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::create_referral(&campaign_owner, &mut campaign, REFERRER_A, &clock, ctx);
                        
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
                        
            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::campaign::campaign::ERefereeExistAlready)]
    fun test_create_referral_exist_referee() {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            let ctx = scenario.ctx();
            let mut clock = clock::create_for_testing(ctx);
            clock.increment_for_testing(1);
            clock.share_for_testing();

            create_campaign();
        };

        scenario.next_tx(ADMIN);
        {
            add_whitelist(REFERRER_B, true);
        };

        scenario.next_tx(REFERRER_B);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::create_referral(&campaign_owner, &mut campaign, REFERRER_A, &clock, ctx);
                        
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
                        
            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }

    #[test]
    fun test_log_user_activity() {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            let ctx = scenario.ctx();
            let mut clock = clock::create_for_testing(ctx);
            clock.increment_for_testing(1);
            clock.share_for_testing();

            create_campaign();
        };

        scenario.next_tx(ADMIN);
        {
            add_whitelist(ADMIN, true);
            add_whitelist(COMMON_USER, true);
        };

        scenario.next_tx(ADMIN);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::log_user_activity(&campaign_owner, &mut campaign, &clock, ctx);
                        
            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.next_tx(COMMON_USER);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::log_user_activity(&campaign_owner, &mut campaign, &clock, ctx);
                        
            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.next_tx(COMMON_USER);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let mut clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            clock.increment_for_testing(1);

            hd::log_user_activity(&campaign_owner, &mut campaign, &clock, ctx);
                        
            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::campaign::campaign::ECampaignEndedAlready)]
    fun test_log_user_activity_referral_ended() {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            let ctx = scenario.ctx();
            let mut clock = clock::create_for_testing(ctx);
            clock.increment_for_testing(1);
            clock.share_for_testing();

            create_campaign();
        };

        scenario.next_tx(ADMIN);
        {
            end_campaign();
        };

        scenario.next_tx(COMMON_USER);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::log_user_activity(&campaign_owner, &mut campaign, &clock, ctx);
                        
            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::campaign::campaign::EPermissionNotExist)]
    fun test_log_user_activity_no_exist_address() {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            let ctx = scenario.ctx();
            let mut clock = clock::create_for_testing(ctx);
            clock.increment_for_testing(1);
            clock.share_for_testing();

            create_campaign();
        };

        scenario.next_tx(COMMON_USER);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::log_user_activity(&campaign_owner, &mut campaign, &clock, ctx);
                        
            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::campaign::campaign::EPermissionNotExist)]
    fun test_log_user_activity_no_permission() {
        let mut scenario = test_scenario::begin(ADMIN);

        scenario.next_tx(ADMIN);
        {
            let ctx = scenario.ctx();
            let mut clock = clock::create_for_testing(ctx);
            clock.increment_for_testing(1);
            clock.share_for_testing();

            create_campaign();
        };

        scenario.next_tx(ADMIN);
        {
            add_whitelist(COMMON_USER, false);
        };

        scenario.next_tx(COMMON_USER);
        {
            let campaign_owner = scenario.take_shared<CampaignOwnerCap>();
            let mut campaign = scenario.take_shared<Campaign>();
            let clock = scenario.take_shared<clock::Clock>();
            let ctx = scenario.ctx();

            hd::log_user_activity(&campaign_owner, &mut campaign, &clock, ctx);
                        
            test_scenario::return_shared(clock);
            test_scenario::return_shared(campaign_owner);
            test_scenario::return_shared(campaign);
        };

        scenario.end();
    }
}

