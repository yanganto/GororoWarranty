/// Module: gororo
module gororo::gororo;

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions

// === Imports ===
use std::string::{Self, String};
use sui::table::{Self, Table};

// === Errors ===
// Use PascalCase for errors, start with an E and be descriptive.
// ex: const ENameHasMaxLengthOf64Chars: u64 = 0;
// https://docs.sui.io/concepts/sui-move-concepts/conventions#errors
const ENotAdmin: u64 = 1;
const EEmptyName: u64 = 2;

// === Structs ===
// * Describe the properties of your structs.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#struct-property-comments
// * Do not use 'potato' in the name of structs. The lack of abilities define it as a potato pattern.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#potato-structs


public struct GororoWarranty has key, store {
    id: UID,
    owner: ID,
}

public struct GororoOwnerCap has key, store {
    id: UID,
}

/// The digital warranty card for driver
public struct Card has key, store {
    id: UID,
    product_serise_number: String,
    // The warranty expire timestamp in ms
    warranty_expiring_at: u64,

    // When repairing, send card to the service provider by send_card_to_repairing_provider
    original_owner: Option<address>,

    repairing_records: Table<u64, RepairingRecord>
}

public struct RepairingRecord has key, store {
    id: UID,
    provider: address,
    description: String
}


// === Method Aliases ===
public use fun issue_warranty_card as GororoWarranty.issue;

public use fun verify_card as Card.verify;
public use fun is_in_repairing as Card.in_repairing;
public use fun send_card_to_repairing_provider as Card.send_to_repair;
public use fun attach_repairing_record_and_return as Card.complete_repair;

// === Public-Mutative Functions ===
// * Name the functions that create data structures as `public fun empty`.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#empty-function
//
// * Name the functions that create objects as `pub fun new`.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#new-function
//
// * Library modules that share objects should provide two functions:
// one to create the object `public fun new(ctx:&mut TxContext): Object`
// and another to share it `public fun share(profile: Profile)`.
// It allows the caller to access its UID and run custom functionality before sharing it.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#new-function
//
// * Name the functions that return a reference as `<PROPERTY-NAME>_mut`, replacing with
// <PROPERTY-NAME\> the actual name of the property.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#reference-functions
//
// * Provide functions to delete objects. Destroy empty objects with the `public fun destroy_empty`
// Use the `public fun drop` for objects that have types that can be dropped.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#destroy-functions
//
// * CRUD functions names
// `add`, `new`, `drop`, `empty`, `remove`, `destroy_empty`, `to_object_name`, `from_object_name`, `property_name_mut`
// https://docs.sui.io/concepts/sui-move-concepts/conventions#crud-functions-names

// Set up a GogoroWarranty, so the brand owner known as publisher, who can issue warranty for the brand after init
// GogoroWarranty will be a public object every one can use the methods thereof
fun init(ctx: &mut TxContext) {
    let owner_cap = GororoOwnerCap {
            id: object::new(ctx),
    };

    transfer::share_object(GororoWarranty {
        id: object::new(ctx),
        owner: object::id(&owner_cap),
    });

    transfer::transfer(owner_cap, tx_context::sender(ctx));
}

// When gororo repairing, the warranty card will send to the repairing service provider
#[allow(lint(custom_state_change))]
public fun send_card_to_repairing_provider(
    mut self: Card,
      repairing_provider: address,
      ctx: &mut TxContext
    ) {
    self.original_owner = option::some(tx_context::sender(ctx));
    transfer::transfer(self, repairing_provider);
}

// Once gororo is repaired, the repairing table of the card will be updated,
// then the warranty card will send back to the owner
#[allow(lint(custom_state_change))]
public fun attach_repairing_record_and_return(
    mut self: Card,
    description: String,
    ctx: &mut TxContext
    ) {
    let current = ctx.epoch_timestamp_ms();

    let record = RepairingRecord {
      id: object::new(ctx),
      provider: tx_context::sender(ctx),
      description,
    };
    let original_owner = self.original_owner.extract();
    self.repairing_records.add(current, record);
    transfer::transfer(self, original_owner);
}

// === Public-View Functions ===
// * Name the functions that return a reference as <<PROPERTY-NAME>, replacing with
// <PROPERTY-NAME\> the actual name of the property.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#reference-functions
//
// * Keep your functions pure to maintain composability. Do not use `transfer::transfer` or
// `transfer::public_transfer` inside core functions.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#pure-functions
//
// * CRUD functions names
// `exists_`, `contains`, `property_name`
// https://docs.sui.io/concepts/sui-move-concepts/conventions#crud-functions-names

public fun verify_card(self: &Card, now: u64): bool {
    self.warranty_expiring_at > now
}

public fun is_in_repairing(self: &Card): bool {
    self.original_owner.is_some()
}

// === Admin Functions ===
// * In admin-gated functions, the first parameter should be the capability. It helps the autocomplete with user types.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#admin-capability
//
// * To maintain composability, use capabilities instead of addresses for access control.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#access-control

public entry fun issue_warranty_card(
    self: &GororoWarranty,
    owner_cap: &GororoOwnerCap,
    product_serise_number: String,
    buyer: address,
    warranty_time_in_ms: u64,
    ctx: &mut TxContext,
) {
    assert!(self.owner == object::id(owner_cap), ENotAdmin);
    assert!(!string::is_empty(&product_serise_number), EEmptyName);

    let warranty_card = Card {
        id: object::new(ctx),
        product_serise_number,
        warranty_expiring_at: ctx.epoch_timestamp_ms() + warranty_time_in_ms,
        original_owner: option::none<address>(),
        repairing_records: table::new<u64, RepairingRecord>(ctx)
    };

    transfer::transfer(warranty_card, buyer);
}
