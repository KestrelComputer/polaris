`timescale 1ns / 1ps

// The decode module is a passive module taking a current state, instruction,
// and other parameters, and yielding one or more minterms to help control
// other functional units in the CPU.

module decode_op_imm(
        output          defined_o,
        output          alua_rf_o,
        output          alub_imm6i_o,
        output          alub_imm12_o,
        output          ra_ir1_o,
        output          ra_ird_o,
        output          rf_alu_o,
        output  [2:0]   nstate_o,
        output  [3:0]   rmask_o,
        output          cflag_1_o,
        output          sum_en_o,
        output          and_en_o,
        output          xor_en_o,
        output          invB_en_o,
        output          lsh_en_o,
        output          rsh_en_o,
        output          ltu_en_o,
        output          lts_en_o,
        output          sx32_en_o,

        input   [2:0]   cstate_i,
        input   [31:0]  ir_i
);
  wire s0 = (cstate_i == 3'b000);
  wire s1 = (cstate_i == 3'b001);
  wire s2 = (cstate_i == 3'b010);

  // Although defined as "registers", these are really asynchronous
  // outputs.

  reg defined_o;
  reg alub_imm6i_o;
  reg alub_imm12_o;
  reg [2:0] nstate_o;
  reg ra_ir1_o;
  reg ra_ird_o;
  reg alua_rf_o;
  reg rf_alu_o;
  reg [3:0] rmask_o;
  reg cflag_1_o;
  reg sum_en_o;
  reg and_en_o;
  reg xor_en_o;
  reg lsh_en_o;
  reg rsh_en_o;
  reg invB_en_o;
  reg ltu_en_o;
  reg lts_en_o;
  reg sx32_en_o;

  always @(*) begin
    case (ir_i[1:0])
      2'b11: begin
      case (ir_i[4:2])
      3'b100, 3'b110: begin
        case (ir_i[6:5])
        2'b00: begin    // OP-IMM
          case (ir_i[14:12])
          3'b000: begin // ADDI
            defined_o <= 1;
            alub_imm6i_o <= 0;
            alub_imm12_o <= s0;
            ra_ir1_o <= s1;
            alua_rf_o <= s2;
            ra_ird_o <= s2;
            rf_alu_o <= s2;
            rmask_o <= {4{s2}};
            cflag_1_o <= 0;
            sum_en_o <= s2;
            and_en_o <= 0;
            xor_en_o <= 0;
            lsh_en_o <= 0;
            rsh_en_o <= 0;
            invB_en_o <= 0;
            ltu_en_o <= 0;
            lts_en_o <= 0;
            sx32_en_o <= s2 & ir_i[3];
          end
          3'b001: begin
            case({ir_i[31:25], ir_i[3]})
            {7'b0000000, 1'b0}, {7'b0000001, 1'b0}: begin	// SLLI
              defined_o <= 1;
              alub_imm6i_o <= s0;
              alub_imm12_o <= 0;
              ra_ir1_o <= s1;
              alua_rf_o <= s2;
              ra_ird_o <= s2;
              rf_alu_o <= s2;
              rmask_o <= {4{s2}};
              cflag_1_o <= 0;
              sum_en_o <= 0;
              and_en_o <= 0;
              xor_en_o <= 0;
              lsh_en_o <= s2;
              rsh_en_o <= 0;
              invB_en_o <= 0;
              ltu_en_o <= 0;
              lts_en_o <= 0;
              sx32_en_o <= 0;
            end
            {7'b0000000, 1'b1}: begin	// SLLIW
              defined_o <= 1;
              alub_imm6i_o <= s0;
              alub_imm12_o <= 0;
              ra_ir1_o <= s1;
              alua_rf_o <= s2;
              ra_ird_o <= s2;
              rf_alu_o <= s2;
              rmask_o <= {4{s2}};
              cflag_1_o <= 0;
              sum_en_o <= 0;
              and_en_o <= 0;
              xor_en_o <= 0;
              lsh_en_o <= s2;
              rsh_en_o <= 0;
              invB_en_o <= 0;
              ltu_en_o <= 0;
              lts_en_o <= 0;
              sx32_en_o <= s2;
            end
            default: begin
              defined_o <= 0;
              alub_imm6i_o <= 0;
              alub_imm12_o <= 0;
              ra_ir1_o <= 0;
              alua_rf_o <= 0;
              ra_ird_o <= 0;
              rf_alu_o <= 0;
              rmask_o <= 4'b0000;
              cflag_1_o <= 0;
              sum_en_o <= 0;
              and_en_o <= 0;
              xor_en_o <= 0;
              lsh_en_o <= 0;
              rsh_en_o <= 0;
              invB_en_o <= 0;
              ltu_en_o <= 0;
              lts_en_o <= 0;
              sx32_en_o <= s2 & ir_i[3];
            end
            endcase
          end
          3'b010: begin // SLTI
            defined_o <= 1;
            alub_imm6i_o <= 0;
            alub_imm12_o <= s0;
            ra_ir1_o <= s1;
            alua_rf_o <= s2;
            ra_ird_o <= s2;
            rf_alu_o <= s2;
            rmask_o <= {4{s2}};
            cflag_1_o <= s2;
            sum_en_o <= 0;
            and_en_o <= 0;
            xor_en_o <= 0;
            lsh_en_o <= 0;
            rsh_en_o <= 0;
            invB_en_o <= s2;
            ltu_en_o <= 0;
            lts_en_o <= s2;
            sx32_en_o <= s2 & ir_i[3];
          end
          3'b011: begin // SLTUI
            defined_o <= 1;
            alub_imm6i_o <= 0;
            alub_imm12_o <= s0;
            ra_ir1_o <= s1;
            alua_rf_o <= s2;
            ra_ird_o <= s2;
            rf_alu_o <= s2;
            rmask_o <= {4{s2}};
            cflag_1_o <= s2;
            sum_en_o <= 0;
            and_en_o <= 0;
            xor_en_o <= 0;
            lsh_en_o <= 0;
            rsh_en_o <= 0;
            invB_en_o <= s2;
            ltu_en_o <= s2;
            lts_en_o <= 0;
            sx32_en_o <= s2 & ir_i[3];
          end
          3'b100: begin // XORI
            defined_o <= 1;
            alub_imm6i_o <= 0;
            alub_imm12_o <= s0;
            ra_ir1_o <= s1;
            alua_rf_o <= s2;
            ra_ird_o <= s2;
            rf_alu_o <= s2;
            rmask_o <= {4{s2}};
            cflag_1_o <= 0;
            sum_en_o <= 0;
            and_en_o <= 0;
            xor_en_o <= s2;
            lsh_en_o <= 0;
            rsh_en_o <= 0;
            invB_en_o <= 0;
            ltu_en_o <= 0;
            lts_en_o <= 0;
            sx32_en_o <= s2 & ir_i[3];
          end
          3'b101: begin
            case({ir_i[31:25], ir_i[3]})
            {7'b0000000, 1'b0}, {7'b0000001, 1'b0}: begin	// SRLI
              defined_o <= 1;
              alub_imm6i_o <= s0;
              alub_imm12_o <= 0;
              ra_ir1_o <= s1;
              alua_rf_o <= s2;
              ra_ird_o <= s2;
              rf_alu_o <= s2;
              rmask_o <= {4{s2}};
              cflag_1_o <= 0;
              sum_en_o <= 0;
              and_en_o <= 0;
              xor_en_o <= 0;
              lsh_en_o <= 0;
              rsh_en_o <= s2;
              invB_en_o <= 0;
              ltu_en_o <= 0;
              lts_en_o <= 0;
              sx32_en_o <= 0;
            end
            {7'b0000000, 1'b1}: begin	// SRLIW
              defined_o <= 1;
              alub_imm6i_o <= s0;
              alub_imm12_o <= 0;
              ra_ir1_o <= s1;
              alua_rf_o <= s2;
              ra_ird_o <= s2;
              rf_alu_o <= s2;
              rmask_o <= {4{s2}};
              cflag_1_o <= 0;
              sum_en_o <= 0;
              and_en_o <= 0;
              xor_en_o <= 0;
              lsh_en_o <= 0;
              rsh_en_o <= s2;
              invB_en_o <= 0;
              ltu_en_o <= 0;
              lts_en_o <= 0;
              sx32_en_o <= s2;
            end
            {7'b0100000, 1'b0}, {7'b0100001, 1'b0}: begin	// SRAI
              defined_o <= 1;
              alub_imm6i_o <= s0;
              alub_imm12_o <= 0;
              ra_ir1_o <= s1;
              alua_rf_o <= s2;
              ra_ird_o <= s2;
              rf_alu_o <= s2;
              rmask_o <= {4{s2}};
              cflag_1_o <= s2;
              sum_en_o <= 0;
              and_en_o <= 0;
              xor_en_o <= 0;
              lsh_en_o <= 0;
              rsh_en_o <= s2;
              invB_en_o <= 0;
              ltu_en_o <= 0;
              lts_en_o <= 0;
              sx32_en_o <= 0;
            end
            {7'b0100000, 1'b1}: begin	// SRAIW
              defined_o <= 1;
              alub_imm6i_o <= s0;
              alub_imm12_o <= 0;
              ra_ir1_o <= s1;
              alua_rf_o <= s2;
              ra_ird_o <= s2;
              rf_alu_o <= s2;
              rmask_o <= {4{s2}};
              cflag_1_o <= s2;
              sum_en_o <= 0;
              and_en_o <= 0;
              xor_en_o <= 0;
              lsh_en_o <= 0;
              rsh_en_o <= s2;
              invB_en_o <= 0;
              ltu_en_o <= 0;
              lts_en_o <= 0;
              sx32_en_o <= s2;
            end
            default: begin
              defined_o <= 0;
              alub_imm6i_o <= 0;
              alub_imm12_o <= 0;
              ra_ir1_o <= 0;
              alua_rf_o <= 0;
              ra_ird_o <= 0;
              rf_alu_o <= 0;
              rmask_o <= 4'b0000;
              cflag_1_o <= 0;
              sum_en_o <= 0;
              and_en_o <= 0;
              xor_en_o <= 0;
              lsh_en_o <= 0;
              rsh_en_o <= 0;
              invB_en_o <= 0;
              ltu_en_o <= 0;
              lts_en_o <= 0;
              sx32_en_o <= 0;
            end
            endcase
          end
          3'b110: begin // ORI
            defined_o <= 1;
            alub_imm6i_o <= 0;
            alub_imm12_o <= s0;
            ra_ir1_o <= s1;
            alua_rf_o <= s2;
            ra_ird_o <= s2;
            rf_alu_o <= s2;
            rmask_o <= {4{s2}};
            cflag_1_o <= 0;
            sum_en_o <= 0;
            and_en_o <= s2;
            xor_en_o <= s2;
            lsh_en_o <= 0;
            rsh_en_o <= 0;
            invB_en_o <= 0;
            ltu_en_o <= 0;
            lts_en_o <= 0;
            sx32_en_o <= s2 & ir_i[3];
          end
          3'b111: begin // ANDI
            defined_o <= 1;
            alub_imm6i_o <= 0;
            alub_imm12_o <= s0;
            ra_ir1_o <= s1;
            alua_rf_o <= s2;
            ra_ird_o <= s2;
            rf_alu_o <= s2;
            rmask_o <= {4{s2}};
            cflag_1_o <= 0;
            sum_en_o <= 0;
            and_en_o <= s2;
            xor_en_o <= 0;
            lsh_en_o <= 0;
            rsh_en_o <= 0;
            invB_en_o <= 0;
            ltu_en_o <= 0;
            lts_en_o <= 0;
            sx32_en_o <= s2 & ir_i[3];
          end
          endcase

          case (cstate_i)
          3'd0: begin
            nstate_o <= 1;
          end
          3'd1: begin
            nstate_o <= 2;
          end
          3'd2: begin
            nstate_o <= 3;
          end
          3'd3: begin
            nstate_o <= 3;
          end
          default: begin
            nstate_o <= cstate_i;
          end
          endcase
        end
        default: begin
          defined_o <= 0;
          alub_imm6i_o <= 0;
          alub_imm12_o <= 0;
          ra_ir1_o <= 0;
          alua_rf_o <= 0;
          ra_ird_o <= 0;
          rf_alu_o <= 0;
          rmask_o <= 4'b0000;
          cflag_1_o <= 0;
          sum_en_o <= 0;
          and_en_o <= 0;
          xor_en_o <= 0;
          lsh_en_o <= 0;
          rsh_en_o <= 0;
          invB_en_o <= 0;
          ltu_en_o <= 0;
          lts_en_o <= 0;
          sx32_en_o <= 0;
        end
        endcase
      end
      default: begin
        defined_o <= 0;
        alub_imm6i_o <= 0;
        alub_imm12_o <= 0;
        ra_ir1_o <= 0;
        alua_rf_o <= 0;
        ra_ird_o <= 0;
        rf_alu_o <= 0;
        rmask_o <= 4'b0000;
        cflag_1_o <= 0;
        sum_en_o <= 0;
        and_en_o <= 0;
        xor_en_o <= 0;
        lsh_en_o <= 0;
        rsh_en_o <= 0;
        invB_en_o <= 0;
        ltu_en_o <= 0;
        lts_en_o <= 0;
        sx32_en_o <= 0;
      end
      endcase
    end
    default: begin
      defined_o <= 0;
      alub_imm6i_o <= 0;
      alub_imm12_o <= 0;
      ra_ir1_o <= 0;
      alua_rf_o <= 0;
      ra_ird_o <= 0;
      rf_alu_o <= 0;
      rmask_o <= 4'b0000;
      cflag_1_o <= 0;
      sum_en_o <= 0;
      and_en_o <= 0;
      xor_en_o <= 0;
      lsh_en_o <= 0;
      rsh_en_o <= 0;
      invB_en_o <= 0;
      ltu_en_o <= 0;
      lts_en_o <= 0;
      sx32_en_o <= 0;
    end
    endcase
  end
endmodule

