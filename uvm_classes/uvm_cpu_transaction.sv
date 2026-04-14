class uvm_cpu_transaction extends uvm_sequence_item;
    `uvm_object_utils(uvm_cpu_transaction)

    rand bit [15:0] instr;
    rand bit [15:0] expected_out;
    rand bit        check_out;
    rand bit        check_flags;
    rand bit        Z, N, V;

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
        check_flags = rhs_.check_flags;
        Z = rhs_.Z;
        N = rhs_.N;
        V = rhs_.V;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        uvm_cpu_transaction rhs_;
        if (!$cast(rhs_, rhs)) return 0;
        return super.do_compare(rhs, comparer) &&
               instr == rhs_.instr &&
               expected_out == rhs_.expected_out &&
               check_out == rhs_.check_out &&
               check_flags == rhs_.check_flags &&
               Z == rhs_.Z &&
               N == rhs_.N &&
               V == rhs_.V;
    endfunction

    function string convert2string();
        return $sformatf("instr=0x%04h, expected_out=0x%04h, check_out=%0b, check_flags=%0b, Z=%0b, N=%0b, V=%0b",
                         instr, expected_out, check_out, check_flags, Z, N, V);
    endfunction
endclass : uvm_cpu_transaction