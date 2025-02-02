module {

    // Create request
    public type CreateRequest = {
        variables : {
            split : [Nat];
        };
    };

    // Modify request
    public type ModifyRequest = {
        split : [Nat];
    };
    
    // Public shared state
    public type Shared = {
        variables : {
            split : [Nat];
        };
    };
}