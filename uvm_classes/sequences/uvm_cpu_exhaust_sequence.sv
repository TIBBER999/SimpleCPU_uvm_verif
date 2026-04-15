class uvm_cpu_exhaust_sequence extends uvm_sequence#(uvm_cpu_transaction);
    `uvm_object_utils(uvm_cpu_exhaust_sequence)

    localparam bit [1:0] SH_NONE = 2'b00;
    localparam bit [1:0] SH_LSL  = 2'b01;
    localparam bit [1:0] SH_LSR  = 2'b10;
    localparam bit [1:0] SH_ASR  = 2'b11;

    function new(string name = "uvm_cpu_exhaust_sequence");
        super.new(name);
    endfunction

    // ── Instruction encoders ──────────────────────────────────────

    function automatic bit [15:0] enc_MOV_imm(
        input bit [2:0] Rn,
        input bit [7:0] imm8
    );
        return {INSTR_MOV_IMM, Rn, imm8};
    endfunction

    function automatic bit [15:0] enc_MOV_shift(
        input bit [2:0] Rd,
        input bit [2:0] Rm,
        input bit [1:0] sh_op = 2'b00
    );
        return {INSTR_MOV_SHIFT, 3'b000, Rd, sh_op, Rm};
    endfunction

    function automatic bit [15:0] enc_ADD(
        input bit [2:0] Rd,
        input bit [2:0] Rn,
        input bit [2:0] Rm,
        input bit [1:0] sh_op = 2'b00
    );
        return {INSTR_ADD, Rn, Rd, sh_op, Rm};
    endfunction

    function automatic bit [15:0] enc_CMP(
        input bit [2:0] Rn,
        input bit [2:0] Rm,
        input bit [1:0] sh_op = 2'b00
    );
        return {INSTR_CMP, Rn, 3'b000, sh_op, Rm};
    endfunction

    function automatic bit [15:0] enc_AND(
        input bit [2:0] Rd,
        input bit [2:0] Rn,
        input bit [2:0] Rm,
        input bit [1:0] sh_op = 2'b00
    );
        return {INSTR_AND, Rn, Rd, sh_op, Rm};
    endfunction

    function automatic bit [15:0] enc_MVN(
        input bit [2:0] Rd,
        input bit [2:0] Rm,
        input bit [1:0] sh_op = 2'b00
    );
        return {INSTR_MVN, 3'b000, Rd, sh_op, Rm};
    endfunction

    // ── Transaction wrappers ──────────────────────────────────────────────
    task send_instr(
        input bit [15:0] instr,
        input bit [15:0] expected_out = 16'h0000,
        input bit Z=0,
        input bit N=0, 
        input bit V=0,
        input bit is_reset = 0);
        uvm_cpu_transaction trans;

        trans = uvm_cpu_transaction::type_id::create("trans");
        start_item(trans);
        trans.instr = instr;
        trans.expected_out = expected_out;
        trans.is_reset = is_reset;
        trans.Z = Z;
        trans.N = N;
        trans.V = V;
        finish_item(trans);
    endtask : send_instr

    task preload_reg_8(input bit [2:0] reg_num, input bit [7:0] val);
        send_instr(enc_MOV_imm(reg_num, val));
    endtask : preload_reg_8

    task send_reset();
        send_instr(16'h0000, 16'h0000, 0, 0, 0, 1);
    endtask : send_reset

    task test_MOV_imm();
        bit [7:0]  imm_vals[6] = '{8'h00, 8'h01, 8'h7F, 8'h80, 8'hFF, 8'hA5};
        $display("\n=== test_MOV_imm ===");
        foreach (imm_vals[i])
            for (int r = 0; r < 8; r++) begin
                $display("Set R%0d= 'h%0h, encoding 'h%0h", r, imm_vals[i], enc_MOV_imm(r[2:0], imm_vals[i]));
                send_instr(enc_MOV_imm(r[2:0], imm_vals[i]));
            end
    endtask : test_MOV_imm

    task test_MOV_shift();
        $display("\n=== test_MOV_shift ===");
        for (int r = 0; r < 8; r++)
            preload_reg_8(r[2:0], 8'b1 << r[2:0]);
        for (int sh = 0; sh < 4; sh++)
            for (int rd = 0; rd < 8; rd++)
                for (int rm = 0; rm < 8; rm++)
                    send_instr(enc_MOV_shift(rd[2:0], rm[2:0], sh[1:0]));
        preload_reg_8(3'd0, 8'h00);
        for (int sh = 0; sh < 4; sh++)
            send_instr(enc_MOV_shift(3'd1, 3'd0, sh[1:0]));
        preload_reg_8(3'd0, 8'hFF);
        send_instr(enc_MOV_shift(3'd1, 3'd0, SH_ASR));
    endtask : test_MOV_shift

    task test_ADD();
        $display("\n=== test_ADD ===");
        preload_reg_8(3'd0, 8'h01);
        preload_reg_8(3'd1, 8'h7F);
        preload_reg_8(3'd2, 8'h80);
        preload_reg_8(3'd3, 8'hFF);
        for (int sh = 0; sh < 4; sh++)
            for (int rn = 0; rn < 4; rn++)
                for (int rm = 0; rm < 4; rm++)
                    send_instr(enc_ADD(3'd4, rn[2:0], rm[2:0], sh[1:0]));
        for (int r = 0; r < 8; r++) begin
            preload_reg_8(r[2:0], 8'h01);
            send_instr(enc_ADD(r[2:0], r[2:0], r[2:0]));
        end
        preload_reg_8(3'd0, 8'h15);
        send_instr(enc_ADD(3'd1, 3'd0, 3'd0));
        preload_reg_8(3'd0, 8'h7F);
        preload_reg_8(3'd1, 8'h7F);
        send_instr(enc_ADD(3'd2, 3'd0, 3'd1));
        preload_reg_8(3'd0, 8'h80);
        preload_reg_8(3'd1, 8'h80);
        send_instr(enc_ADD(3'd2, 3'd0, 3'd1));
    endtask : test_ADD

    task test_CMP();
        $display("\n=== test_CMP ===");

        // ── Z=1 : equal values ────────────────────────────────────────
        // R0 = sximm8(0x55) = 0x0055
        // R1 = sximm8(0x55) = 0x0055
        // 0x0055 - 0x0055 = 0x0000  →  Z=1, N=0, V=0
        preload_reg_8(3'd0, 8'h55);
        preload_reg_8(3'd1, 8'h55);
        send_instr(enc_CMP(3'd0, 3'd1));

        // ── N=1 : Rn < Rm (both positive, no overflow) ────────────────
        // R0 = sximm8(0x01) = 0x0001
        // R1 = sximm8(0x7F) = 0x007F
        // 0x0001 - 0x007F = 0xFF82  →  Z=0, N=1, V=0
        // V=0 because: a[15]=0, b[15]=0, same sign → no signed overflow
        preload_reg_8(3'd0, 8'h01);
        preload_reg_8(3'd1, 8'h7F);
        send_instr(enc_CMP(3'd0, 3'd1));

        // ── Clean (N=0, Z=0, V=0) : Rn > Rm, both positive ──────────
        // R0 = sximm8(0x7F) = 0x007F
        // R1 = sximm8(0x01) = 0x0001
        // 0x007F - 0x0001 = 0x007E  →  Z=0, N=0, V=0
        preload_reg_8(3'd0, 8'h7F);
        preload_reg_8(3'd1, 8'h01);
        send_instr(enc_CMP(3'd0, 3'd1));

        // ── V=1 : signed overflow, positive minus negative → negative ─
        //
        // preload_reg_8 sign-extends imm8 to 16 bits, so values 0x80–0xFF
        // become 0xFF80–0xFFFF (negative in 16-bit two's complement).
        // A plain 8-bit load cannot place a large enough positive value in a
        // register to overflow 16-bit subtraction, because the maximum
        // positive value loadable is sximm8(0x7F) = 0x007F.
        //
        // Strategy: build 0x4000 in R0 by loading 0x01 then doubling 14×
        //           via  ADD R0, R0, R0  (each ADD doubles the value):
        //   after  1 ADD:  0x0002
        //   after  2 ADDs: 0x0004
        //   ...
        //   after 14 ADDs: 0x4000
        //
        // Build 0xC001 in R2:
        //   Load R2 = sximm8(0x80) = 0xFF80  (= −128 in 16-bit signed)
        //   Load R3 = sximm8(0x7F) = 0x007F
        //   ADD  R2, R2, R3  →  0xFF80 + 0x007F = 0xFFFF  (= −1)
        //   Then double R2 fourteen times with ADD R2, R2, R2:
        //   after  1 ADD: 0xFFFE  (−2)
        //   ...
        //   after 14 ADDs: 0xFFFE << 13 = 0xC000  (−16384)
        //   ADD R2, R2, R1  where R1 still holds 0x0001 → R2 = 0xC001
        //
        // CMP R0, R2  →  0x4000 - 0xC001
        //   = 0x4000 + ~0xC001 + 1
        //   = 0x4000 + 0x3FFE + 1
        //   = 0x7FFF
        // a[15]=0 (positive), b[15]=1 (negative), result[15]=0
        // Overflow condition: (a[15] != b[15]) && (result[15] != a[15])
        //   = (0 != 1) && (0 != 0) = true && false = 0  ← still no overflow
        //
        // Re-examine: need result to flip to NEGATIVE.
        // Use 0x4001 - 0xC000:
        //   = 0x4001 + 0x4000 = 0x8001  →  result[15]=1
        //   a[15]=0, b[15]=1, result[15]=1
        //   (0 != 1) && (1 != 0) → V=1  ✓  N=1  Z=0
        //
        // Build 0x4001 in R0:
        //   Load R0=0x01 (=0x0001), double 14× → 0x4000,
        //   Load R1=0x01 (=0x0001), ADD R0,R0,R1 → 0x4001
        //
        // Build 0xC000 in R2:
        //   Load R2=0x80 → 0xFF80, double (ADD R2,R2,R2) 9× →
        //   0xFF80 << 9 in 16-bit:
        //   ×1 : 0xFF00
        //   ×2 : 0xFE00
        //   ×3 : 0xFC00
        //   ×4 : 0xF800
        //   ×5 : 0xF000
        //   ×6 : 0xE000
        //   ×7 : 0xC000  ✓  (only 7 doublings needed)
        //
        // Final check: CMP R0(0x4001), R2(0xC000)
        //   result = 0x4001 - 0xC000 = 0x8001
        //   a[15]=0, b[15]=1, result[15]=1  →  V=1, N=1, Z=0  ✓

        // Build R0 = 0x4001
        preload_reg_8(3'd0, 8'h01);            // R0 = 0x0001
        repeat (14)
            send_instr(enc_ADD(3'd0, 3'd0, 3'd0));  // R0 doubles × 14 → 0x4000
        preload_reg_8(3'd1, 8'h01);            // R1 = 0x0001
        send_instr(enc_ADD(3'd0, 3'd0, 3'd1));      // R0 = 0x4000 + 0x0001 = 0x4001

        // Build R2 = 0xC000
        preload_reg_8(3'd2, 8'h80);            // R2 = sximm8(0x80) = 0xFF80
        repeat (7)
            send_instr(enc_ADD(3'd2, 3'd2, 3'd2));  // R2 doubles × 7 → 0xC000

        send_instr(enc_CMP(3'd0, 3'd2));
        // expected: 0x4001 - 0xC000 = 0x8001  →  V=1, N=1, Z=0
        // ── Shift variants of CMP (V=0 path, no writeback side-effect) ─
        // R0 = sximm8(0x10) = 0x0010
        // R1 = sximm8(0x04) = 0x0004
        // sh=0 (NONE): 0x0010 - 0x0004 = 0x000C  → N=0 Z=0 V=0
        // sh=1 (LSL):  0x0010 - 0x0008 = 0x0008  → N=0 Z=0 V=0
        // sh=2 (LSR):  0x0010 - 0x0002 = 0x000E  → N=0 Z=0 V=0
        // sh=3 (ASR):  0x0010 - 0x0002 = 0x000E  → N=0 Z=0 V=0
        preload_reg_8(3'd0, 8'h10);
        preload_reg_8(3'd1, 8'h04);
        for (int sh = 0; sh < 4; sh++)
            send_instr(enc_CMP(3'd0, 3'd1, sh[1:0]));

        // ── No writeback check ─────────────────────────────────────────
        // CMP must NOT write the ALU result back to any register.
        // After the shift-variant CMPs above, R0 should still be 0x0010.
        // We preload R5=0x42=0x0042, run one more CMP (R0,R1, no shift),
        // then MOV R6 ← R5.  If CMP incorrectly wrote back, R0 or another
        // register is corrupted and the MOV will return the wrong value.
        preload_reg_8(3'd5, 8'h42);            // R5 = 0x0042
        send_instr(enc_CMP(3'd0, 3'd1));
        send_instr(enc_MOV_shift(3'd6, 3'd5));

    endtask : test_CMP

    task test_AND();
        $display("\n=== test_AND ===");
        preload_reg_8(3'd0, 8'hFF);
        preload_reg_8(3'd1, 8'h00);
        send_instr(enc_AND(3'd2, 3'd0, 3'd1));
        preload_reg_8(3'd0, 8'hA5);
        preload_reg_8(3'd1, 8'hFF);
        send_instr(enc_AND(3'd2, 3'd0, 3'd1));
        for (int r = 0; r < 8; r++) begin
            preload_reg_8(r[2:0], 8'hA5);
            send_instr(enc_AND(r[2:0], r[2:0], r[2:0]));
        end
        preload_reg_8(3'd0, 8'hA5);
        preload_reg_8(3'd1, 8'h5A);
        send_instr(enc_AND(3'd2, 3'd0, 3'd1));
        preload_reg_8(3'd0, 8'hAA);
        preload_reg_8(3'd1, 8'h55);
        for (int sh = 0; sh < 4; sh++)
            send_instr(enc_AND(3'd2, 3'd0, 3'd1, sh[1:0]));
    endtask : test_AND

    task test_MVN();
        $display("\n=== test_MVN ===");
        preload_reg_8(3'd0, 8'h00);
        send_instr(enc_MVN(3'd1, 3'd0));
        preload_reg_8(3'd0, 8'hFF);
        send_instr(enc_MVN(3'd1, 3'd0));
        preload_reg_8(3'd0, 8'h7F);
        send_instr(enc_MVN(3'd1, 3'd0));
        preload_reg_8(3'd0, 8'h80);
        send_instr(enc_MVN(3'd1, 3'd0));
        preload_reg_8(3'd0, 8'hA5);
        send_instr(enc_MVN(3'd1, 3'd0));
        send_instr(enc_MVN(3'd2, 3'd1));
        for (int r = 0; r < 8; r++) begin
            preload_reg_8(r[2:0], 8'hA5);
            send_instr(enc_MVN(r[2:0], r[2:0]));
        end
        preload_reg_8(3'd0, 8'hAA);
        for (int sh = 0; sh < 4; sh++)
            send_instr(enc_MVN(3'd1, 3'd0, sh[1:0]));
    endtask : test_MVN

    task test_sequences();
        $display("\n=== test_sequences ===");
        send_instr(enc_MOV_imm  (3'd0, 8'h0A));
        send_instr(enc_MOV_imm  (3'd1, 8'h05));
        send_instr       (enc_ADD      (3'd2, 3'd0, 3'd1));
        send_instr       (enc_CMP      (3'd2, 3'd1)     );
        send_instr       (enc_AND      (3'd3, 3'd2, 3'd0));
        send_instr       (enc_MVN      (3'd4, 3'd3)     );
        send_instr       (enc_MOV_shift(3'd5, 3'd4)     );
        send_instr(enc_MOV_imm(3'd0, 8'h00));
        send_instr(enc_MOV_imm(3'd1, 8'h01));
        repeat (8) send_instr(enc_ADD(3'd0, 3'd0, 3'd1));
        send_instr(enc_MOV_imm(3'd0, 8'h10));
        send_instr(enc_MOV_imm(3'd1, 8'h10));
        repeat (4) begin
            send_instr(enc_CMP(3'd0, 3'd1));
        end
        repeat (4) send_instr(enc_ADD(3'd0, 3'd0, 3'd0));
        repeat (4) send_instr(enc_MVN(3'd1, 3'd1));
    endtask : test_sequences

    task test_reset();
        $display("\n=== test_reset ===");
        
        // 1. Send an instruction to alter the CPU state
        send_instr(enc_ADD(3'd0, 3'd1, 3'd2));
        
        // 2. Trigger the UVM-compliant reset transaction
        send_reset();
        
        // 3. Send instructions to verify CPU operates normally from a fresh state
        send_instr(enc_MOV_imm(3'd0, 8'h0F));
        send_instr(enc_MOV_imm(3'd1, 8'h01));
        send_instr(enc_ADD(3'd2, 3'd0, 3'd1));
        
        // 4. Send another state-altering instruction
        send_instr(enc_AND(3'd3, 3'd0, 3'd1));
        
        // 5. Trigger a second reset to ensure multiple resets work
        send_reset();
        
        // 6. Verify CPU is responsive again
        send_instr(enc_MOV_imm(3'd7, 8'hAB));
    endtask : test_reset

    task test_w_protocol();
        $display("\n=== test_w_protocol ===");
        send_instr(enc_MOV_imm(3'd0, 8'hAA));
        send_instr(enc_ADD(3'd1, 3'd0, 3'd0));
        send_instr(enc_CMP(3'd0, 3'd0));
    endtask : test_w_protocol

    task test_random(input int unsigned num_ops = 300);
        bit [15:0] instr;
        bit [2:0]  rd, rn, rm;
        bit [1:0]  sh;
        bit [7:0]  imm;
        int        op_sel;
        $display("\n=== test_random (%0d ops) ===", num_ops);
        for (int r = 0; r < 8; r++) begin
            imm = $urandom_range(0, 255);
            send_instr(enc_MOV_imm(r[2:0], imm));
        end
        repeat (num_ops) begin
            rd     = $urandom_range(0, 7);
            rn     = $urandom_range(0, 7);
            rm     = $urandom_range(0, 7);
            sh     = $urandom_range(0, 3);
            imm    = $urandom_range(0, 255);
            op_sel = $urandom_range(0, 5);
            case (op_sel)
                0: instr = enc_MOV_imm  (rd,         imm);
                1: instr = enc_MOV_shift(rd,     rm, sh);
                2: instr = enc_ADD      (rd, rn, rm, sh);
                3: instr = enc_CMP      (    rn, rm, sh);
                4: instr = enc_AND      (rd, rn, rm, sh);
                5: instr = enc_MVN      (rd,     rm, sh);
            endcase
            send_instr(instr);
        end
    endtask : test_random
    
    // Task to hit all defined instruction transitions
    task test_transitions();
        $display("=== Starting Directed Transitions Test ===");

        // Target: MOV_IMM => ADD
        send_instr(enc_MOV_imm(3'd0, 8'h01)); // R0 = 1
        send_instr(enc_MOV_imm(3'd1, 8'h02)); // R1 = 2
        send_instr(enc_ADD(3'd2, 3'd0, 3'd1, SH_NONE));

        // Target: MOV_IMM => CMP
        send_instr(enc_MOV_imm(3'd0, 8'h05));
        send_instr(enc_CMP(3'd0, 3'd1, SH_NONE));

        // Target: MOV_IMM => AND
        send_instr(enc_MOV_imm(3'd0, 8'hFF));
        send_instr(enc_AND(3'd2, 3'd0, 3'd1, SH_NONE));

        // Target: MOV_IMM => MVN
        send_instr(enc_MOV_imm(3'd0, 8'hAA));
        send_instr(enc_MVN(3'd2, 3'd0, SH_NONE));

        // Target: MOV_IMM => MOV_SHIFT
        send_instr(enc_MOV_imm(3'd0, 8'h01));
        send_instr(enc_MOV_shift(3'd1, 3'd0, SH_LSL));
    endtask
    
    task test_output_corners();
        $display("=== Starting Output Corners Test ===");
 
        // Bin: zero (16'h0000)
        send_instr(enc_MOV_imm(3'd0, 8'h00));
        send_instr(enc_MOV_shift(3'd1, 3'd0, SH_NONE));
 
        // Bin: all_ones (16'hFFFF)
        // MVN of sximm8(0x00)=0x0000 → ~0x0000 = 0xFFFF
        send_instr(enc_MOV_imm(3'd0, 8'h00));
        send_instr(enc_MVN(3'd1, 3'd0, SH_NONE));
 
        // Bin: max_pos (16'h7FFF)
        // Build 0x7FFF: load 0x01, double 14× → 0x4000,
        // load 0x7F → 0x007F, MVN → 0xFF80, MVN again → 0x007F,
        // then ADD 0x4000 + 0x3FFF.
        // Simpler: load 0xFF→0x00FF, MVN→0xFF00, MVN→0x00FF,
        // build 0x7F00 via shifts and OR isn't available.
        // Best direct route: load 0x80→0xFF80, MVN→0x007F (=R1),
        //   load 0x01, double 14× → 0x4000 (R0),
        //   ADD R2, R0, R1 → 0x407F  (not 0x7FFF).
        // Use repeated doubling + subtract approach:
        //   0x7FFF = 0x8000 - 1
        //   Load 0x80→0xFF80, double 8× → 0x8000, then ADD 0xFFFF
        //   0xFFFF = MVN(0x0000)
        //   0x8000 + 0xFFFF = 0x7FFF (mod 16-bit)
        preload_reg_8(3'd0, 8'h80);                      // R0 = 0xFF80
        repeat (8)
            send_instr(enc_ADD(3'd0, 3'd0, 3'd0)); // R0 → 0x8000
        preload_reg_8(3'd1, 8'h00);                      // R1 = 0x0000
        send_instr(enc_MVN(3'd1, 3'd1));           // R1 = 0xFFFF
        send_instr(enc_ADD(3'd2, 3'd0, 3'd1));            // R2 = 0x8000+0xFFFF = 0x7FFF
 
        // Bin: min_neg (16'h8000)
        // Load 0x80→0xFF80, double 8× → 0x8000
        preload_reg_8(3'd0, 8'h80);                      // R0 = 0xFF80
        repeat (8)
            send_instr(enc_ADD(3'd0, 3'd0, 3'd0)); // R0 → 0x8000
        send_instr(enc_MOV_shift(3'd1, 3'd0, SH_NONE));  // R1 = 0x8000
    endtask : test_output_corners

    task body();
        test_MOV_imm();
        test_MOV_shift();
        test_ADD();
        
        test_CMP();
        test_AND();
        test_MVN();
        
        test_sequences();
        
        test_reset();
        test_w_protocol();
        test_transitions();
        test_output_corners();
        test_random(300);
    endtask
endclass : uvm_cpu_exhaust_sequence