import ICRC55 "mo:devefi/ICRC55";
import T "./vector_modules";
import Rechain "mo:rechain";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";

module {

    public type DispatchAction = {
        ts : Nat64;
        caller : Principal;
        payload : {
            #vector : ICRC55.BatchCommandRequest<T.CreateRequest, T.ModifyRequest>;
        };
    };

    public type DispatchActionError = { ok : Nat; err : Text };

    public func encodeBlock(b : DispatchAction) : ?[Rechain.ValueMap] {
        switch (b.payload) {
            case (#vector(_v)) {
                ?[
                    ("btype", #Text("55vec")),
                    ("c", #Blob(to_candid (b))),
                ];
            };
        };
    };

};
