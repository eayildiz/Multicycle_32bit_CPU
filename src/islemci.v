`timescale 1ns/1ps

`define BELLEK_ADRES    32'h8000_0000
`define VERI_BIT        32
`define ADRES_BIT       32
`define YAZMAC_SAYISI   32

module islemci (
    input                       clk,
    input                       rst,
    output  [`ADRES_BIT-1:0]    bellek_adres,
    input   [`VERI_BIT-1:0]     bellek_oku_veri,
    output  [`VERI_BIT-1:0]     bellek_yaz_veri,
    output                      bellek_yaz
);

anabellek anabellek_(clk, bellek_adres, bellek_oku_veri, bellek_yaz_veri, bellek_yaz);

localparam GETIR        = 2'd0;
localparam COZYAZMACOKU = 2'd1;
localparam YURUTGERIYAZ = 2'd2;

reg [1:0] simdiki_asama_r;
reg [1:0] simdiki_asama_ns;
reg ilerle_cmb;

reg [`VERI_BIT-1:0] yazmac_obegi [0:`YAZMAC_SAYISI-1];
reg [`VERI_BIT-1:0] islenecek_buyruk;
reg [`ADRES_BIT-1:0] ps_r;
reg [`ADRES_BIT-1:0] ps_ns;

//Mikroislemler yazmaclari
reg [`VERI_BIT-1:0] kaynak_yazmac_1_veri;
reg [`VERI_BIT-1:0] kaynak_yazmac_2_veri;
reg [4:0] sonuc_yazmac;
reg [2:0] islem_kodu;

always @ * begin
    case(simdiki_asama_r)
        
        GETIR:
        begin
            islenecek_buyruk = bellek_oku_veri;  //Islenmesi gereken buyrugun program sayaci bellege gonderilir ve gelenbuyruk bir sonraki aşama için kayıt edilir. 
            ps_ns = ps_r + 4;   //Getir asamasi istek yapildiktan sonra saatin yukselen kenarinda program sayacini gunceller.
            simdiki_asama_ns = COZYAZMACOKU;
        end
        
        /*Olası iyilestirmeler
        * rs1 icin sondan 3. bit 0 veya buyruk 1100111.
        * 1. bit 1 ise dallanma vardir. 
        */
        COZYAZMACOKU:
        begin
            case(islenecek_buyruk[6:2])
                01100:
                begin
                    kaynak_yazmac_2_veri = yazmac_obegi[islenecek_buyruk[24:20]];
                    kaynak_yazmac_1_veri = yazmac_obegi[islenecek_buyruk[19:15]];

                    sonuc_yazmac = islenecek_buyruk[11:7];
                    
                    islem_kodu = islenecek_buyruk[14:12]
                end

            endcase
        end

        //TODO: cozulen mikroislemlerle gore hangi islemlerin yapilacagini da ilet. 
    
    endcase
    ilerle_cmb = 0;
    simdiki_asama_ns = simdiki_asama_r;
end

always @(posedge clk) begin
    if (rst) begin
        ps_r <= `BELLEK_ADRES;
        simdiki_asama_r <= GETIR;
    end
    else begin
        if (ilerle_cmb) begin
            simdiki_asama_r <= simdiki_asama_ns;
        end
        ps_r <= ps_ns
    end
end

assign bellek_adres = ps_r;
assign bellek_yaz_veri = 32'h0;
assign bellek_yaz = 1'b0;

endmodule
