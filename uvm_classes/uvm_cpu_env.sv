class uvm_cpu_env extends uvm_env;
    `uvm_component_utils(uvm_cpu_env)

    uvm_cpu_agent agent_h;
    uvm_cpu_scoreboard scoreboard_h;
    uvm_cpu_coverage coverage_h;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent_h = uvm_cpu_agent::type_id::create("agent_h", this);
        scoreboard_h = uvm_cpu_scoreboard::type_id::create("scoreboard_h", this);
        coverage_h = uvm_cpu_coverage::type_id::create("coverage_h", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agent_h.monitor_h.ap.connect(coverage.analysis_export);
    endfunction
endclass : uvm_cpu_env