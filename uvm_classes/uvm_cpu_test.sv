class uvm_cpu_test extends uvm_test;
    `uvm_component_utils(uvm_cpu_test)

    uvm_cpu_env env;
    virtual cpu_bfm bfm;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = uvm_cpu_env::type_id::create("env", this);
        if (!uvm_config_db#(virtual cpu_bfm)::get(this, "", "bfm", bfm))
            `uvm_error("TEST", "BFM not found");
        uvm_config_db#(virtual cpu_bfm)::set(this, "env.agent.driver_h", "bfm", bfm);
        uvm_config_db#(virtual cpu_bfm)::set(this, "env.agent.monitor_h", "bfm", bfm);
    endfunction

    task run_phase(uvm_phase phase);
        uvm_cpu_exhaust_sequence seq;
        phase.raise_objection(this);
        bfm.reset_cpu();
        env.scoreboard_h.reset();
        seq = uvm_cpu_exhaust_sequence::type_id::create("seq");
        seq.start(env.agent_h.sequencer_h);
        phase.drop_objection(this);
    endtask
endclass : uvm_cpu_test