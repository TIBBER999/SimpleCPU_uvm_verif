class uvm_cpu_agent extends uvm_agent;
    `uvm_component_utils(uvm_cpu_agent)

    uvm_cpu_driver driver_h;
    uvm_cpu_monitor monitor_h;
    uvm_cpu_sequence sequencer_h;
    uvm_analysis_port #(uvm_cpu_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        ap= new("ap", this);
        driver_h= uvm_cpu_driver::type_id::create("driver_h", this);
        sequencer_h= uvm_cpu_sequence::type_id::create("sequencer_h", this);
        monitor_h= uvm_cpu_monitor::type_id::create("monitor_h", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        driver_h.seq_item_port.connect(sequencer_h.seq_item_export);
        my_monitor_h.ap.connect(ap);
    endfunction
endclass : uvm_cpu_agent