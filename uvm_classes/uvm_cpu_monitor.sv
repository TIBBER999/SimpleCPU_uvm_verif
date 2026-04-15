class uvm_cpu_monitor extends uvm_monitor;
    `uvm_component_utils(uvm_cpu_monitor)

    virtual cpu_bfm bfm;
    uvm_analysis_port#(uvm_cpu_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual cpu_bfm)::get(this, "", "bfm", bfm))
            `uvm_error("MON", "BFM not found")
    endfunction

    task run_phase(uvm_phase phase);
        uvm_cpu_transaction trans;

        fork 
        forever begin
            @(posedge bfm.clk);
            if (bfm.load) begin
                trans = uvm_cpu_transaction::type_id::create("trans");
                trans.instr = bfm.in;
                trans.check_out= 0;
                `uvm_info("MON", $sformatf("Monitor LOAD observed instruction: 0x%0h", trans.instr), UVM_LOW)
                ap.write(trans);
            end
        end
        forever begin
            @(posedge bfm.w) begin
                trans = uvm_cpu_transaction::type_id::create("trans");
                trans.expected_out = bfm.out;
                trans.Z = bfm.Z;
                trans.N = bfm.N;
                trans.V = bfm.V;
                trans.check_out= 1;
                `uvm_info("MON", $sformatf("Monitor Start observed result: 0x%0h", trans.expected_out), UVM_LOW)
                ap.write(trans);
            end
        end
        join
    endtask
endclass : uvm_cpu_monitor