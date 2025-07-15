module tests::campaign_object_locking {
    use sui::test_scenario;
    use sui::clock;
    use sui::tx_context::{Self, TxContext};
    use std::string::utf8;
    use campaign::campaign;

    #[test]
    public fun test_add_whitelist_multiple_times() {
        let mut ctx = test_scenario::new_tx_context();
        let clock = clock::Clock { timestamp_ms: 1 };

        // Create admin cap and campaign
        campaign::init_for_testing(&mut ctx);
        let title = utf8(b"Test Campaign");
        let about = utf8(b"About this campaign");
        campaign::create_campaign(
            /* admin_cap: */ &campaign::AdminCap { id: sui::object::new(&mut ctx) },
            title,
            about,
            &clock,
            &mut ctx
        );

        // Fetch the campaign object (simulate, as test_scenario would provide it)
        // For illustration, assume campaign_id is known or fetched
        let campaign_id = /* ... get campaign object id ... */;
        let campaign_obj = borrow_global<campaign::Campaign>(campaign_id);

        // Call add_whitelist twice in the same transaction (should succeed)
        campaign::add_whitelist(&campaign_obj, @0x1, true, &mut ctx);
        campaign::add_whitelist(&campaign_obj, @0x2, true, &mut ctx);

        // If you try to mutate the same UserWhitelist object twice, it would fail:
        // let mut whitelist = ...; // get &mut UserWhitelist
        // campaign::update_permission_whitelist(&campaign_obj, &mut whitelist, false, &mut ctx);
        // campaign::update_permission_whitelist(&campaign_obj, &mut whitelist, true, &mut ctx);
        // ^ This would cause a locking error if both used the same &mut in one transaction
    }
}