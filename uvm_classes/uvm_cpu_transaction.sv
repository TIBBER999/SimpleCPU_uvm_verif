class uvm_cpu_transaction extends uvm_sequence_item;
    `uvm_object_utils(uvm_cpu_transaction)

    rand bit [15:0] instr;
    rand bit [15:0] expected_out;
    rand bit        check_out;
    rand bit        Z, N, V;
    rand bit        is_reset;

    function new(string name = "uvm_cpu_transaction");
        super.new(name);
    endfunction

    function void do_copy(uvm_object rhs);
        uvm_cpu_transaction rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_error("do_copy", "Cast failed")
            return;
        end
        
        if (rhs == null)
            `uvm_fatal("do_copy", "Tried to copy from a null pointer");
            
        super.do_copy(rhs);
        instr = rhs_.instr;
        expected_out = rhs_.expected_out;
        check_out = rhs_.check_out;
        Z = rhs_.Z;
        N = rhs_.N;
        V = rhs_.V;
        is_reset = rhs_.is_reset;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        uvm_cpu_transaction rhs_;
        if (!$cast(rhs_, rhs)) return 0;
        return super.do_compare(rhs, comparer) &&
               instr == rhs_.instr &&
               expected_out == rhs_.expected_out &&
               check_out == rhs_.check_out &&
               Z == rhs_.Z &&
               N == rhs_.N &&
               V == rhs_.V &&
               is_reset == rhs_.is_reset;
    endfunction

    function string convert2string();
        instr_t cmd;
        cmd = instr_t'(instr[15:11]);
        return $sformatf("instr=0x%04h, cmd=%s, expected_out=0x%04h, check_out=%0b, Z=%0b, N=%0b, V=%0b, is_reset=%0b",
                         instr, cmd.name(), expected_out, check_out, Z, N, V, is_reset);
    endfunction
endclass : uvm_cpu_transaction