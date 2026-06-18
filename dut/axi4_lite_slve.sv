`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.06.2026 13:37:52
// Design Name: 
// Module Name: axi_slave
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// Register Map
// 0x00 : CTRL   (RW)
//        bit0 : Enable
//        bit1 : Soft Reset
//
// 0x04 : CONFIG (RW)
//
// 0x08 : STATUS (RO)
//        bit0 : Done
//        bit1 : Error
//
// 0x0C : DATA   (RW)

module axi_slave(
  input logic clk,rst_n,
  // write address channel:
  input logic  AWVALID,
  input logic [31:0] AWADDR,
  output logic AWREADY,
  
  // write data channel:
  input logic WVALID,
  input logic [31:0] WDATA,
  output logic WREADY,
  
  // respond channel:
  input logic BREADY,
  output logic [1:0] BRESP,
  output logic BVALID,
  
  // read address channel:
  
  input logic ARVALID,
  input logic [31:0] ARADDR,
  output logic ARREADY,
  
  // read data channel:
  input logic RREADY,
  output logic RVALID,
  output logic [1:0] RRESP,
  output logic [31:0] RDATA);
  
  // register declaration
  logic [31:0] ctrl_reg, config_reg, status_reg, data_reg;
  
  typedef enum logic [1:0] {
  W_IDLE,
  W_WRITE,
  W_RESPOND}wstate_t;
  wstate_t wstate,w_next;
  
  typedef enum logic [1:0] {
  R_IDLE,
  R_READ,
  R_RESPOND}rstate_t;
  rstate_t rstate,r_next;
  
  // state register
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wstate<=W_IDLE;
      rstate<=R_IDLE;
      
    end
    else begin
      wstate <= w_next;
      rstate <= r_next;
    end
  end
  
  // next state logic
  always_comb begin
    w_next =wstate;
    r_next=rstate;
    case(wstate)
      W_IDLE: begin
        if((AWVALID && AWREADY) && (WVALID && WREADY))
          w_next=W_WRITE;
        
      end
      
      W_WRITE:
        w_next = W_RESPOND;
      
      W_RESPOND: begin
        if(BVALID && BREADY)
          w_next =W_IDLE;
       
      end
      default : w_next = W_IDLE;
    endcase
    
    case(rstate)
      R_IDLE:
        begin
        if(ARVALID && ARREADY)
          r_next = R_READ;
        end
      
      R_READ:
        	r_next = R_RESPOND;
      
      R_RESPOND: begin
        if(RVALID && RREADY)
          r_next = R_IDLE;
        
      end
      default: r_next = R_IDLE;
    endcase
  end
  
  // outputs
  always_comb begin
      AWREADY = 0;
      WREADY  = 0;
  	  BVALID  = 0;

  	  ARREADY = 0;
  	  RVALID  = 0;

  	  BRESP   = 2'b00;// 0 means OKAY
  	  RRESP   = 2'b00;
    case(wstate)
      
      W_IDLE: 
        begin
          AWREADY =1;
          WREADY =1;
          BVALID =0;
        end
      W_WRITE:
        begin
          AWREADY =0;
          WREADY=0;
          BVALID=0;
        end
      W_RESPOND:
        begin
          AWREADY=0;
          WREADY=0;
          BVALID=1;
        end
    endcase
    
    case(rstate)
      R_IDLE:
        begin
          ARREADY =1;
          RVALID=0;
        end
      R_READ:
        begin
          ARREADY=0;
          RVALID=0;
        end
      R_RESPOND:
        begin
          ARREADY=0;
          RVALID=1;
        end
    endcase
  end
  
  // address decoding
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      ctrl_reg<=32'b0;
      config_reg<=32'b0;
      status_reg<=32'b0;
      data_reg<=32'b0;
    end
    else if(wstate==W_WRITE) begin
    
    case(AWADDR)
      32'h00: ctrl_reg<= WDATA;
      32'h04: config_reg <= WDATA;
      //32'h0x08: status_reg <= WDATA;
      32'h0C: data_reg <= WDATA;
    endcase
    end
  end
  always_comb begin
    RDATA=32'h0;
    if(rstate==R_READ||rstate==R_RESPOND) begin
    case(ARADDR)
      32'h00: RDATA = ctrl_reg;
      32'h04: RDATA = config_reg;
      32'h08: RDATA = status_reg;
      32'h0C: RDATA = data_reg;
      default: RDATA =32'h0;
    endcase
    end
  end
endmodule
