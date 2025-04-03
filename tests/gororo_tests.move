#[test_only]
module gororo::gororo_tests;

use std::string;
use gororo::gororo::{init, GororoWarranty, GororoOwnerCap, Card};

#[test]
fun test_issued_warranty_card_can_transfer() {
    use sui::test_scenario;
    use std::debug;

    let gororo_admin: address = @0xAAAA;
    let first_buyer: address = @0x0001;
    let second_buyer: address = @0x0002;
    let technician: address = @0xFFFF;


    let mut scenario = test_scenario::begin(gororo_admin);
    {
        // NOTE:
        // If you run `sui move test` locally, please use `test_for_init`.
        // The github CI use a customized sui-move, such that you can use any package init function.
        // https://github.com/sui-foundation/2025-Sui-Hacker-House-template/blob/c5f6fae44592efc9f7cc2b79f05f5805c27ad24b/sources/template.move#L78-L81
        init(scenario.ctx());
    };

    scenario.next_tx(gororo_admin);
    {
        // warranty for a brand is created globally
        let warranty = scenario.take_shared<GororoWarranty>();
        // debug::print(&warranty);

        // Admin will have cap after init contract
        let cap = scenario.take_from_sender<GororoOwnerCap>();
        // debug::print(&cap);

        // First buyer buy a gororo, admin issue a warranty card to him
        warranty.issue(&cap, string::utf8(b"SN:1234"), first_buyer, 50000, scenario.ctx());

        test_scenario::return_shared(warranty);
        scenario.return_to_sender(cap);
    };

    scenario.next_tx(first_buyer);
    {
        // First buyer can transfer the warranty card when sell the product to second buyer in real world
        let warranty_card = scenario.take_from_address<Card>(first_buyer);
        sui::transfer::public_transfer(warranty_card, second_buyer);
    };

    scenario.next_tx(second_buyer);
    {
        // Second buyer send gororo to repair
        let warranty_card = scenario.take_from_address<Card>(second_buyer);
        warranty_card.send_to_repair(technician, scenario.ctx());
    };

    scenario.next_tx(technician);
    {
        // Technician complete repairing and return the warranty card
        let warranty_card = scenario.take_from_address<Card>(technician);
        warranty_card.complete_repair(string::utf8(b"Replace the lamp"), scenario.ctx());
    };

    scenario.next_tx(second_buyer);
    {
        let warranty_card = scenario.take_from_address<Card>(second_buyer);
        debug::print(&warranty_card);
        scenario.return_to_sender(warranty_card);
    };

    scenario.end();
}
