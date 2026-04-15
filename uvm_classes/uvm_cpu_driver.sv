class uvm_cpu_driver extends uvm_driver#(uvm_cpu_transaction);
    `uvm_component_utils(uvm_cpu_driver)

    virtual cpu_bfm bfm;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual cpu_bfm)::get(this, "", "bfm", bfm))
            `uvm_error("DRV", "BFM not found")
    endfunction

    task run_phase(uvm_phase phase);
        uvm_cpu_transaction trans;
        bit [15:0] result;

        forever begin
            seq_item_port.get_next_item(trans);
            if (trans.is_reset) begin
                `uvm_info("DRV", "Received reset transaction, asserting reset on BFM", UVM_MEDIUM)
                bfm.reset_cpu();
            end else begin
                `uvm_info("DRV", $sformatf("Received transaction: %s", trans.convert2string()), UVM_MEDIUM)
                // Send the instruction
                bfm.send_cmd(.s2(1'b0), .load2(1'b1), .in2(trans.instr), .out2(result));
                bfm.send_cmd(.s2(1'b1), .load2(1'b0), .in2(trans.instr), .out2(result));
                // Wait for w signal
                @(posedge bfm.w);
            end
            seq_item_port.item_done();
        end
    endtask
endclass : uvm_cpu_driver