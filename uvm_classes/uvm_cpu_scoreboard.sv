class uvm_cpu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(uvm_cpu_scoreboard)

    virtual cpu_bfm bfm;

    bit [15:0] instr_reg[$];
    bit [15:0] register[8];
    bit flag_Z, flag_N, flag_V;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual cpu_bfm)::get(this, "", "bfm", bfm))
            `uvm_error("SCOREBOARD", "BFM not found")
    endfunction

    function void reset();
        instr_reg.delete();
        for (int i = 0; i < 8; i++)
            register[i] = 16'h0000;
        flag_Z = 1'b0;
        flag_N = 1'b0;
        flag_V = 1'b0;
    endfunction

    function automatic bit [15:0] do_shift(bit [15:0] val, bit [1:0] sh);
        case (sh)
            2'b00: return val;
            2'b01: return {val[14:0], 1'b0};
            2'b10: return {1'b0, val[15:1]};
            2'b11: return {val[15], val[15:1]};
            default: return val;
        endcase
    endfunction

    function automatic void update_flags(
        bit [15:0] a, bit [15:0] b, bit [15:0] result, bit is_sub
    );
        flag_Z = (result == 16'h0000);
        flag_N = result[15];
        if (is_sub)
            flag_V = (a[15] != b[15]) && (result[15] != a[15]);
        else
            flag_V = 0;
    endfunction

    task run_phase(uvm_phase phase);
        bit [15:0] cmd_in;
        bit [15:0] predicted_out;
        bit [2:0] Rn, Rd, Rm;
        bit [1:0] sh_op;
        bit [15:0] shifted_Rm;
        bit [16:0] add_full;
        instr_t decoded;

        forever begin : self_checker
            @(posedge bfm.clk);

            if (bfm.load)
                instr_reg.push_back(bfm.in);

            if (bfm.s && (instr_reg.size() > 0)) begin
                cmd_in = instr_reg.pop_front();
                Rn = cmd_in[10:8];
                Rd = cmd_in[7:5];
                Rm = cmd_in[2:0];
                sh_op = cmd_in[4:3];
                shifted_Rm = do_shift(register[Rm], sh_op);
                decoded = instr_t'(cmd_in[15:11]);

                case (decoded)
                    INSTR_MOV_IMM: begin
                        register[Rn] = {{8{cmd_in[7]}}, cmd_in[7:0]};
                        predicted_out = register[Rn];
                        @(posedge bfm.w);
                        if (bfm.out !== predicted_out)
                            `uvm_error("SCOREBOARD", $sformatf("MOV_IMM FAILED: predicted=0x%04h, DUT=0x%04h", predicted_out, bfm.out))
                        else
                            `uvm_info("SCOREBOARD", $sformatf("MOV_IMM PASSED: out=0x%04h", bfm.out), UVM_MEDIUM)
                    end

                    INSTR_MOV_SHIFT: begin
                        register[Rd] = shifted_Rm;
                        predicted_out = register[Rd];
                        @(posedge bfm.w);
                        if (bfm.out !== predicted_out)
                            `uvm_error("SCOREBOARD", $sformatf("MOV_SHIFT FAILED: predicted=0x%04h, DUT=0x%04h", predicted_out, bfm.out))
                        else
                            `uvm_info("SCOREBOARD", $sformatf("MOV_SHIFT PASSED: out=0x%04h", bfm.out), UVM_MEDIUM)
                    end

                    INSTR_ADD: begin
                        add_full = {1'b0, register[Rn]} + {1'b0, shifted_Rm};
                        register[Rd] = add_full[15:0];
                        predicted_out = register[Rd];
                        @(posedge bfm.w);
                        if (bfm.out !== predicted_out)
                            `uvm_error("SCOREBOARD", $sformatf("ADD FAILED: predicted=0x%04h, DUT=0x%04h", predicted_out, bfm.out))
                        else
                            `uvm_info("SCOREBOARD", $sformatf("ADD PASSED: out=0x%04h", bfm.out), UVM_MEDIUM)
                    end

                    INSTR_CMP: begin
                        bit [15:0] diff;
                        diff = register[Rn] - shifted_Rm;
                        update_flags(register[Rn], shifted_Rm, diff, 1'b1);
                        @(posedge bfm.w);
                        if (bfm.Z !== flag_Z || bfm.N !== flag_N || bfm.V !== flag_V)
                            `uvm_error("SCOREBOARD", $sformatf("CMP FAILED: pred{V,N,Z}=%03b, DUT{V,N,Z}=%03b", {flag_V, flag_N, flag_Z}, {bfm.V, bfm.N, bfm.Z}))
                        else
                            `uvm_info("SCOREBOARD", $sformatf("CMP PASSED: {V,N,Z}=%03b", {bfm.V, bfm.N, bfm.Z}), UVM_MEDIUM)
                    end

                    INSTR_AND: begin
                        register[Rd] = register[Rn] & shifted_Rm;
                        predicted_out = register[Rd];
                        @(posedge bfm.w);
                        if (bfm.out !== predicted_out)
                            `uvm_error("SCOREBOARD", $sformatf("AND FAILED: predicted=0x%04h, DUT=0x%04h", predicted_out, bfm.out))
                        else
                            `uvm_info("SCOREBOARD", $sformatf("AND PASSED: out=0x%04h", bfm.out), UVM_MEDIUM)
                    end

                    INSTR_MVN: begin
                        register[Rd] = ~shifted_Rm;
                        predicted_out = register[Rd];
                        @(posedge bfm.w);
                        if (bfm.out !== predicted_out)
                            `uvm_error("SCOREBOARD", $sformatf("MVN FAILED: predicted=0x%04h, DUT=0x%04h", predicted_out, bfm.out))
                        else
                            `uvm_info("SCOREBOARD", $sformatf("MVN PASSED: out=0x%04h", bfm.out), UVM_MEDIUM)
                    end

                    default: begin
                        `uvm_warning("SCOREBOARD", $sformatf("Unknown instruction 5'b%05b — skipped", cmd_in[15:11]))
                    end
                endcase
            end
        end : self_checker
    endtask
endclass : uvm_cpu_scoreboard