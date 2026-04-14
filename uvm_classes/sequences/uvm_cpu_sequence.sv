class uvm_cpu_sequence extends uvm_sequence#(uvm_cpu_transaction);
    `uvm_object_utils(uvm_cpu_sequence)

    function new(string name = "uvm_cpu_sequence");
        super.new(name);
    endfunction

    task body();
        uvm_cpu_transaction trans;

        // Simple test: send a MOV_IMM instruction
        trans = uvm_cpu_transaction::type_id::create("trans");
        start_item(trans);
        trans.instr = {INSTR_MOV_IMM, 3'b000, 8'h42}; // MOV R0, 0x42
        finish_item(trans);

        // Then execute
        trans = uvm_cpu_transaction::type_id::create("trans");
        start_item(trans);
        trans.instr = {INSTR_MOV_IMM, 3'b000, 8'h42}; // Same, but for execution
        trans.check_out = 1;
        finish_item(trans);
    endtask
endclass : uvm_cpu_sequence