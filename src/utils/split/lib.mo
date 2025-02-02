import MU "mo:mosup";
import Ver1 "./memory/v1";
import Map "mo:map/Map";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Core "mo:devefi/core";
import I "./interface";

module {
    let T = Core.VectorModule;
    public let Interface = I;

    public module Mem {
        public module Vector {
            public let V1 = Ver1;
        };
    };
    let VM = Mem.Vector.V1;

    public let ID = "devefi_split";

    public class Mod({
        xmem : MU.MemShell<VM.Mem>;
        core : Core.Mod;
    }) : T.Class<I.CreateRequest, I.ModifyRequest, I.Shared> {

        let mem = MU.access(xmem);

        public func meta() : T.Meta {
            {
                id = ID; // This has to be same as the variant in vec.custom
                name = "Split";
                author = "Neutrinite";
                description = "Split X tokens by weighted shares";
                supported_ledgers = [];
                version = #alpha([0, 0, 1]);
                create_allowed = true;
                ledger_slots = [
                    "Split",
                ];
                billing = [
                    {
                        cost_per_day = 0;
                        transaction_fee = #none;
                    },
                ];
                sources = sources(0);
                destinations = destinations(0);
                author_account = {
                    owner = Principal.fromText("6jvpj-sqaaa-aaaaj-azwnq-cai");
                    subaccount = null;
                };
                temporary_allowed = true;
            };
        };

        public func create(id : T.NodeId, req : T.CommonCreateRequest, t : I.CreateRequest) : T.Create {

            let obj : VM.NodeMem = {
                variables = {
                    var split = t.variables.split;
                };
            };
            ignore Map.put(mem.main, Map.n32hash, id, obj);
            #ok(ID);
        };

        public func get(id : T.NodeId, vec : T.NodeCoreMem) : T.Get<I.Shared> {
            let ?t = Map.get(mem.main, Map.n32hash, id) else return #err("Not found");

            #ok {
                variables = {
                    split = t.variables.split;
                };
            };
        };

        public func modify(id : T.NodeId, m : I.ModifyRequest) : T.Modify {
            let ?t = Map.get(mem.main, Map.n32hash, id) else return #err("Not found");

            t.variables.split := m.split;
            #ok();
        };

        public func delete(id : T.NodeId) : T.Delete {
            ignore Map.remove(mem.main, Map.n32hash, id);
            #ok;
        };

        public func defaults() : I.CreateRequest {
            {
                variables = {
                    split = [50, 50];
                };
            };
        };

        public func run() : () {
            label vec_loop for ((vid, parm) in Map.entries(mem.main)) {
                let ?vec = core.getNodeById(vid) else continue vec_loop;
                if (not vec.active) continue vec_loop;
                Run.single(vid, vec, parm);
            };
        };

        module Run {
            public func single(vid : T.NodeId, vec : T.NodeCoreMem, n : VM.NodeMem) : () {

                let ?source = core.getSource(vid, vec, 0) else return;
                let bal = core.Source.balance(source);
                let fee = core.Source.fee(source);

                // First loop: Calculate totalSplit and find the largest share destination
                var totalSplit = 0;
                var largestPort : ?Nat = null;
                var largestAmount = 0;

                label iniloop for (port_id in n.variables.split.keys()) {
                    if (not core.hasDestination(vec, port_id)) continue iniloop;

                    let splitShare = n.variables.split[port_id];
                    totalSplit += splitShare;

                    if (splitShare > largestAmount) {
                        largestPort := ?port_id;
                        largestAmount := splitShare;
                    };
                };

                // If no valid destinations, skip the rest of the loop
                if (totalSplit == 0) return;

                var remainingBalance = bal;

                // Second loop: Send to each valid destination
                label port_send for (port_id in n.variables.split.keys()) {
                    if (not core.hasDestination(vec, port_id)) continue port_send;

                    let splitShare = n.variables.split[port_id];

                    // Skip the largestPort for now, as we will handle it last
                    if (?port_id == largestPort) continue port_send;

                    let amount = bal * splitShare / totalSplit;
                    if (amount <= fee * 100) continue port_send; // Skip if below fee threshold

                    let #ok(intent) = core.Source.Send.intent(source, #destination({ port = port_id }), amount) else return;
                    ignore core.Source.Send.commit(intent);
                    remainingBalance -= amount;
                };

                // Send the remaining balance to the largest share destination
                if (remainingBalance > 0) {
                    ignore do ? {
                        let #ok(intent) = core.Source.Send.intent(source, #destination({ port = largestPort! }), remainingBalance) else return;
                        ignore core.Source.Send.commit(intent);
                    };
                };

            };
        };

        public func sources(_id : T.NodeId) : T.Endpoints {
            [(0, "")];
        };

        public func destinations(id : T.NodeId) : T.Endpoints {
            let ?t = Map.get(mem.main, Map.n32hash, id) else return [];

            Array.tabulate<(Nat, Text)>(
                t.variables.split.size(),
                func(idx : Nat) { (0, Nat.toText(t.variables.split[idx])) },
            );
        };

    };

};
