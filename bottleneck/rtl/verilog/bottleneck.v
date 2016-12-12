`timescale 1ns / 1ps

module bottleneck(
	input	[63:0]	m_adr_i,
	input		m_cyc_i,
	input	[63:0]	m_dat_i,
	input		m_signed_i,
	input	[1:0]	m_siz_i,
	input		m_stb_i,
	input		m_we_i,
	output		m_ack_o,
	output	[63:0]	m_dat_o,

	output	[63:0]	s_adr_o,
	output		s_cyc_o,
	output		s_signed_o,
	output		s_siz_o,
	output		s_stb_o,
	output		s_we_o,
	output	[15:0]	s_dat_o,
	input		s_ack_i,
	input	[15:0]	s_dat_i
);
	wire [63:0] s_dat_8s = {{56{s_dat_i[7]}}, s_dat_i[7:0]};
	wire [63:0] s_dat_8u = {56'd0, s_dat_i[7:0]};

	wire [15:0] m_dat_8 = {8'h00, m_dat_i[7:0]};

	assign s_adr_o = m_adr_i;
	assign s_cyc_o = m_cyc_i;
	assign s_signed_o = m_signed_i;
	assign s_siz_o = m_siz_i[0];
	assign s_stb_o = m_stb_i;
	assign s_we_o = m_we_i;
	assign s_dat_o = m_dat_8;

	assign m_ack_o = s_ack_i;
	assign m_dat_o = (m_signed_i) ? s_dat_8s : s_dat_8u;
endmodule

