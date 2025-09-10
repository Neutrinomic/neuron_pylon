import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Rechain "mo:rechain";
import RT "./rechain";
import Timer "mo:base/Timer";
import T "./vector_modules";
import U "mo:devefi/utils";
import MU_sys "mo:devefi/sys";
import Ledgers "mo:devefi/ledgers";
import ICRC55 "mo:devefi/ICRC55";
import VecIcpNeuron "mo:devefi-jes1-icpneuron";
import VecSnsNeuron "mo:devefi-jes1-snsneuron";
import VecNtcMint "mo:devefi-jes1-ntc/mint";
import VecNtcRedeem "mo:devefi-jes1-ntc/redeem";
import VecSplit "./utils/split/";
import Core "mo:devefi/core";
import Chrono "mo:chronotrinite/client";

actor class (DFV_SETTINGS : ?Core.SETTINGS) = this {

    let me_can = Principal.fromActor(this);
    stable let chain_mem = Rechain.Mem.Rechain.V1.new();

    var chain = Rechain.Chain<system, RT.DispatchAction, RT.DispatchActionError>({
        settings = ?{
            Rechain.DEFAULT_SETTINGS with supportedBlocks = [{
                block_type = "55vec";
                url = "https://github.com/dfinity/ICRC/issues/55";
            }];
        };
        xmem = chain_mem;
        encodeBlock = RT.encodeBlock;
        reducers = [];
        me_can;
    });

    stable let chrono_mem_v1 = Chrono.Mem.ChronoClient.V1.new({
        router = Principal.fromText("hik73-dyaaa-aaaal-qsaqa-cai");
    });

    let chrono = Chrono.ChronoClient<system>({ xmem = chrono_mem_v1 });

    stable let dvf_mem_1 = Ledgers.Mem.Ledgers.V1.new();
    stable let dvf_mem_2 = Ledgers.Mem.Ledgers.V2.upgrade(dvf_mem_1);

    let dvf = Ledgers.Ledgers<system>({ xmem = dvf_mem_2; me_can; chrono });

    stable let mem_core_1 = Core.Mem.Core.V1.new();

    let core = Core.Mod<system>({
        _chrono = chrono;
        xmem = mem_core_1;
        settings = Option.get(
            DFV_SETTINGS,
            {
                PYLON_NAME = "Neuron";
                PYLON_GOVERNED_BY = "Neutrinite DAO";
                BILLING = {
                    ledger = Principal.fromText("f54if-eqaaa-aaaaq-aacea-cai");
                    min_create_balance = 200000000;
                    operation_cost = 20_000;
                    freezing_threshold_days = 10;
                    split = {
                        platform = 20;
                        pylon = 10;
                        author = 50;
                        affiliate = 20;
                    };
                    pylon_account = {
                        owner = Principal.fromText("eqsml-lyaaa-aaaaq-aacdq-cai");
                        subaccount = null;
                    };
                    platform_account = {
                        owner = Principal.fromText("eqsml-lyaaa-aaaaq-aacdq-cai");
                        subaccount = null;
                    };
                };
                TEMP_NODE_EXPIRATION_SEC = 3600;
                MAX_INSTRUCTIONS_PER_HEARTBEAT = 300_000_000;
                REQUEST_MAX_EXPIRE_SEC = 3600;
                ALLOW_TEMP_NODE_CREATION = false;
            } : Core.SETTINGS,
        );
        dvf;
        me_can;
    });

    // Vector modules
    stable let mem_vec_icpneuron_1 = VecIcpNeuron.Mem.Vector.V1.new();
    stable let mem_vec_icpneuron_2 = VecIcpNeuron.Mem.Vector.V2.upgrade(mem_vec_icpneuron_1);
    stable let mem_vec_icpneuron_3 = VecIcpNeuron.Mem.Vector.V3.upgrade(mem_vec_icpneuron_2);
    stable let mem_vec_icpneuron_4 = VecIcpNeuron.Mem.Vector.V4.upgrade(mem_vec_icpneuron_3);

    stable let mem_vec_snsneuron_1 = VecSnsNeuron.Mem.Vector.V1.new();
    stable let mem_vec_snsneuron_2 = VecSnsNeuron.Mem.Vector.V2.upgrade(mem_vec_snsneuron_1);

    stable let mem_vec_split_1 = VecSplit.Mem.Vector.V1.new();

    stable let mem_vec_ntc_mint_1 = VecNtcMint.Mem.Vector.V1.new();

    stable let mem_vec_ntc_redeem_1 = VecNtcRedeem.Mem.Vector.V1.new();

    let devefi_jes1_icpneuron = VecIcpNeuron.Mod({
        xmem = mem_vec_icpneuron_4;
        core;
    });

    let devefi_jes1_snsneuron = VecSnsNeuron.Mod({
        xmem = mem_vec_snsneuron_2;
        core;
    });

    let devefi_split = VecSplit.Mod({
        xmem = mem_vec_split_1;
        core;
    });

    let devefi_jes1_ntc_mint = VecNtcMint.Mod({
        xmem = mem_vec_ntc_mint_1;
        core;
        dvf;
    });

    let devefi_jes1_ntc_redeem = VecNtcRedeem.Mod({
        xmem = mem_vec_ntc_redeem_1;
        core;
    });

    let vmod = T.VectorModules({
        devefi_jes1_icpneuron;
        devefi_jes1_snsneuron;
        devefi_split;
        devefi_jes1_ntc_mint;
        devefi_jes1_ntc_redeem;
    });

    let sys = MU_sys.Mod<system, T.CreateRequest, T.Shared, T.ModifyRequest>({
        xmem = mem_core_1;
        dvf;
        core;
        vmod;
        me_can;
    });

    private func proc() {
        devefi_jes1_icpneuron.run();
        devefi_jes1_snsneuron.run();
        devefi_split.run();
        devefi_jes1_ntc_mint.run();
        devefi_jes1_ntc_redeem.run();
    };

    private func async_proc() : async* () {
        await* devefi_jes1_icpneuron.runAsync();
        await* devefi_jes1_snsneuron.runAsync();
        await* devefi_jes1_ntc_mint.runAsync();
    };

    ignore Timer.recurringTimer<system>(
        #seconds 30,
        func() : async () { core.heartbeat(proc) },
    );

    ignore Timer.recurringTimer<system>(
        #seconds 45,
        func() : async () { await* async_proc() },
    );

    // ICRC-55

    public query func icrc55_get_pylon_meta() : async ICRC55.PylonMetaResp {
        sys.icrc55_get_pylon_meta();
    };

    public shared ({ caller }) func icrc55_command(req : ICRC55.BatchCommandRequest<T.CreateRequest, T.ModifyRequest>) : async ICRC55.BatchCommandResponse<T.Shared> {
        sys.icrc55_command<RT.DispatchActionError>(
            caller,
            req,
            func(r) {
                chain.dispatch({
                    caller;
                    payload = #vector(r);
                    ts = U.now();
                });
            },
        );
    };

    public query func icrc55_command_validate(req : ICRC55.BatchCommandRequest<T.CreateRequest, T.ModifyRequest>) : async ICRC55.ValidationResult {
        #Ok(debug_show (req));
    };

    public query func icrc55_get_nodes(req : [ICRC55.GetNode]) : async [?MU_sys.NodeShared<T.Shared>] {
        sys.icrc55_get_nodes(req);
    };

    public query ({ caller }) func icrc55_get_controller_nodes(req : ICRC55.GetControllerNodesRequest) : async [MU_sys.NodeShared<T.Shared>] {
        sys.icrc55_get_controller_nodes(caller, req);
    };

    public query func icrc55_get_defaults(id : Text) : async T.CreateRequest {
        sys.icrc55_get_defaults(id);
    };

    public shared ({ caller }) func icrc55_account_register(acc : ICRC55.Account) : async () {
        sys.icrc55_account_register(caller, acc);
    };

    public query ({ caller }) func icrc55_accounts(req : ICRC55.AccountsRequest) : async ICRC55.AccountsResponse {
        sys.icrc55_accounts(caller, req);
    };

    // ICRC-3

    public query func icrc3_get_blocks(args : Rechain.GetBlocksArgs) : async Rechain.GetBlocksResult {
        return chain.icrc3_get_blocks(args);
    };

    public query func icrc3_get_archives(args : Rechain.GetArchivesArgs) : async Rechain.GetArchivesResult {
        return chain.icrc3_get_archives(args);
    };

    public query func icrc3_supported_block_types() : async [Rechain.BlockType] {
        return chain.icrc3_supported_block_types();
    };
    public query func icrc3_get_tip_certificate() : async ?Rechain.DataCertificate {
        return chain.icrc3_get_tip_certificate();
    };

    public shared ({ caller }) func icpneuron_vote({
        caller_subaccount : ?Blob;
        vid : Nat32;
        neuronId : Nat64;
        proposal : Nat64;
        vote : Int32;
    }) : async { #ok; #err : Text } {
        return await* devefi_jes1_icpneuron.vote({
            caller = { owner = caller; subaccount = caller_subaccount };
            vid = vid;
            neuronId = neuronId;
            proposal = proposal;
            vote = vote;
        });
    };

    public shared ({ caller }) func icpneuron_split({
        caller_subaccount : ?Blob;
        vid : Nat32;
        neuronId : Nat64;
        amount_e8s : Nat64;
    }) : async { #ok; #err : Text } {
        return await* devefi_jes1_icpneuron.split({
            caller = { owner = caller; subaccount = caller_subaccount };
            vid = vid;
            neuronId = neuronId;
            amount_e8s = amount_e8s;
        });
    };

    // ---------- Debug functions -----------

    let admin_id = Principal.fromText("v6ksx-vfv66-dlpks-agv2k-2pafk-yjlow-5fesr-dxigk-rzvzp-xrfbg-tae");

    public shared ({ caller }) func add_supported_ledger(id : Principal, ltype : { #icp; #icrc }) : () {
        assert ((caller == admin_id) or (Principal.isController(caller)));
        dvf.add_ledger<system>(id, ltype);
    };

    public query func get_ledger_errors() : async [[Text]] {
        dvf.getErrors();
    };

    public query func get_ledgers_info() : async [Ledgers.LedgerInfo] {
        dvf.getLedgersInfo();
    };

    public query func get_pending_transactions() : async [Ledgers.PendingTransactions] {
        dvf.getPendingTransactions();
    };

    public shared ({ caller }) func clear_pending_transactions() : async () {
        assert ((caller == admin_id) or (Principal.isController(caller)));
        dvf.clearPendingTransactions();
    };

};
