import ICRC55 "mo:devefi/ICRC55";
import Core "mo:devefi/core";
import VecIcpNeuron "mo:devefi-jes1-icpneuron";
import VecSnsNeuron "mo:devefi-jes1-snsneuron";
import VecSplit "./utils/split/";
import Result "mo:base/Result";
import Debug "mo:base/Debug";

module {

    public type CreateRequest = {
        #devefi_jes1_icpneuron : VecIcpNeuron.Interface.CreateRequest;
        #devefi_jes1_snsneuron : VecSnsNeuron.Interface.CreateRequest;
        #devefi_split : VecSplit.Interface.CreateRequest;
    };

    public type Shared = {
        #devefi_jes1_icpneuron : VecIcpNeuron.Interface.Shared;
        #devefi_jes1_snsneuron : VecSnsNeuron.Interface.Shared;
        #devefi_split : VecSplit.Interface.Shared;
    };

    public type ModifyRequest = {
        #devefi_jes1_icpneuron : VecIcpNeuron.Interface.ModifyRequest;
        #devefi_jes1_snsneuron : VecSnsNeuron.Interface.ModifyRequest;
        #devefi_split : VecSplit.Interface.ModifyRequest;
    };

    public class VectorModules(
        m : {
            devefi_jes1_icpneuron : VecIcpNeuron.Mod;
            devefi_jes1_snsneuron : VecSnsNeuron.Mod;
            devefi_split : VecSplit.Mod;
        }
    ) {

        public func get(mid : Core.ModuleId, id : Core.NodeId, vec : Core.NodeMem) : Result.Result<Shared, Text> {

            if (mid == VecIcpNeuron.ID) {
                switch (m.devefi_jes1_icpneuron.get(id, vec)) {
                    case (#ok(x)) return #ok(#devefi_jes1_icpneuron(x));
                    case (#err(x)) return #err(x);
                };
            };

            if (mid == VecSnsNeuron.ID) {
                switch (m.devefi_jes1_snsneuron.get(id, vec)) {
                    case (#ok(x)) return #ok(#devefi_jes1_snsneuron(x));
                    case (#err(x)) return #err(x);
                };
            };

            if (mid == VecSplit.ID) {
                switch (m.devefi_split.get(id, vec)) {
                    case (#ok(x)) return #ok(#devefi_split(x));
                    case (#err(x)) return #err(x);
                };
            };

            #err("Unknown variant");
        };

        public func getDefaults(mid : Core.ModuleId) : CreateRequest {
            if (mid == VecIcpNeuron.ID) return #devefi_jes1_icpneuron(m.devefi_jes1_icpneuron.defaults());
            if (mid == VecSnsNeuron.ID) return #devefi_jes1_snsneuron(m.devefi_jes1_snsneuron.defaults());
            if (mid == VecSplit.ID) return #devefi_split(m.devefi_split.defaults());
            Debug.trap("Unknown variant");

        };

        public func sources(mid : Core.ModuleId, id : Core.NodeId) : Core.EndpointsDescription {
            if (mid == VecIcpNeuron.ID) return m.devefi_jes1_icpneuron.sources(id);
            if (mid == VecSnsNeuron.ID) return m.devefi_jes1_snsneuron.sources(id);
            if (mid == VecSplit.ID) return m.devefi_split.sources(id);
            Debug.trap("Unknown variant");

        };

        public func destinations(mid : Core.ModuleId, id : Core.NodeId) : Core.EndpointsDescription {
            if (mid == VecIcpNeuron.ID) return m.devefi_jes1_icpneuron.destinations(id);
            if (mid == VecSnsNeuron.ID) return m.devefi_jes1_snsneuron.destinations(id);
            if (mid == VecSplit.ID) return m.devefi_split.destinations(id);
            Debug.trap("Unknown variant");
        };

        public func create(id : Core.NodeId, creq : Core.CommonCreateRequest, req : CreateRequest) : Result.Result<Core.ModuleId, Text> {

            switch (req) {
                case (#devefi_jes1_icpneuron(t)) return m.devefi_jes1_icpneuron.create(id, creq, t);
                case (#devefi_jes1_snsneuron(t)) return m.devefi_jes1_snsneuron.create(id, creq, t);
                case (#devefi_split(t)) return m.devefi_split.create(id, creq, t);
            };
            #err("Unknown variant or mismatch");
        };

        public func modify(mid : Core.ModuleId, id : Core.NodeId, creq : ModifyRequest) : Result.Result<(), Text> {
            switch (creq) {
                case (#devefi_jes1_icpneuron(r)) if (mid == VecIcpNeuron.ID) return m.devefi_jes1_icpneuron.modify(id, r);
                case (#devefi_jes1_snsneuron(r)) if (mid == VecSnsNeuron.ID) return m.devefi_jes1_snsneuron.modify(id, r);
                case (#devefi_split(r)) if (mid == VecSplit.ID) return m.devefi_split.modify(id, r);
            };
            #err("Unknown variant or mismatch");
        };

        public func delete(mid : Core.ModuleId, id : Core.NodeId) : Result.Result<(), Text> {
            if (mid == VecIcpNeuron.ID) return m.devefi_jes1_icpneuron.delete(id);
            if (mid == VecSnsNeuron.ID) return m.devefi_jes1_snsneuron.delete(id);
            if (mid == VecSplit.ID) return m.devefi_split.delete(id);
            Debug.trap("Unknown variant");
        };

        public func nodeMeta(mid : Core.ModuleId) : ICRC55.ModuleMeta {
            if (mid == VecIcpNeuron.ID) return m.devefi_jes1_icpneuron.meta();
            if (mid == VecSnsNeuron.ID) return m.devefi_jes1_snsneuron.meta();
            if (mid == VecSplit.ID) return m.devefi_split.meta();
            Debug.trap("Unknown variant");
        };

        public func meta() : [ICRC55.ModuleMeta] {
            [
                m.devefi_jes1_icpneuron.meta(),
                m.devefi_jes1_snsneuron.meta(),
                m.devefi_split.meta(),
            ];
        };

    };
};