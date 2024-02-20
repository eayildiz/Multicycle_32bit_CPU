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

reg [`VERI_BIT:0] bellek_veri_adres_ns;
reg [`VERI_BIT:0] bellek_yaz_veri_ns;
reg [`VERI_BIT:0] bellek_yaz_ns;

reg [`VERI_BIT:0] bellek_adres_r;
reg [`VERI_BIT:0] bellek_yaz_veri_r;
reg [`VERI_BIT:0] bellek_yaz_r;

//Mikroislemler yazmaclari
reg [`VERI_BIT:0] anlik_deger;
reg [`VERI_BIT-1:0] kaynak_yazmac_1_veri;
reg [`VERI_BIT-1:0] kaynak_yazmac_2_veri;
reg [4:0] sonuc_yazmac;
reg [2:0] islem_kodu;   //AMB icin detaylar



//TODO: diger always bloguna gecisi kodla.
always @ * begin
    case(simdiki_asama_r)
        
        GETIR:
        begin
            islenecek_buyruk = bellek_oku_veri;  //Islenmesi gereken buyrugun program sayaci bellege gonderilir ve gelenbuyruk bir sonraki aşama için kayıt edilir. 
            ps_ns = ps_r + 4;   //Getir asamasi istek yapildiktan sonra saatin yukselen kenarinda program sayacini gunceller.
            ilerle_cmb = 1;
            simdiki_asama_ns = COZYAZMACOKU;
        end
        
        /*Olasi iyilestirmeler
        * rs1 icin sondan 3. bit 0 veya buyruk 1100111.
        * 1. bit 1 ise dallanma vardir.
        * Ayni islemleri yapanları birleştirmeyi dusun.
        */
        COZYAZMACOKU:
        begin
            case(islenecek_buyruk[6:2])
                00000:  //LW
                begin
                    //12 bit deger isaretle 32 bit oluyor.
                    anlik_deger = islenecek_buyruk[31:20];
                    if(anlik_deger[11] == 1'b1)
                        anlik_deger[31:12] = 20'b11_111_111_111_111_111_111;
                    else
                        anlik_deger[31:12] = 12'b00_000_000_000_000_000_000;
                    

                    kaynak_yazmac_1_veri = yazmac_obegi[islenecek_buyruk[19:15]];
                    sonuc_yazmac = islenecek_buyruk[11:7];
                end
                
                00100:  //ADDI
                begin
                    //12 bit deger isaretle 32 bit oluyor.
                    anlik_deger = islenecek_buyruk[31:20];
                    if(anlik_deger[11] == 1'b1)
                        anlik_deger[31:12] = 20'b11_111_111_111_111_111_111;
                    else
                        anlik_deger[31:12] = 12'b00_000_000_000_000_000_000;

                    kaynak_yazmac_1_veri = yazmac_obegi[islenecek_buyruk[19:15]];
                    sonuc_yazmac = islenecek_buyruk[11:7];
                end

                00101:  //AUIPC
                begin
                    anlik_deger = islenecek_buyruk[31:12] << 12;

                    sonuc_yazmac = islenecek_buyruk[11:7];
                end

                01000:  //SW
                begin
                    //12 bit deger isaretle 32 bit oluyor.
                    anlik_deger = (islenecek_buyruk[31:25] <<< 5 + islenecek_buyruk[24:20]);
                    if(anlik_deger[11] == 1'b1)
                        anlik_deger[31:12] = 20'b11_111_111_111_111_111_111;
                    else
                        anlik_deger[31:12] = 20'b00_000_000_000_000_000_000;

                    kaynak_yazmac_2_veri = yazmac_obegi[islenecek_buyruk[24:20]];
                    kaynak_yazmac_1_veri = yazmac_obegi[islenecek_buyruk[19:15]];
                end
                
                01100:  //AMB buyruklari
                begin
                    kaynak_yazmac_2_veri = yazmac_obegi[islenecek_buyruk[24:20]];
                    kaynak_yazmac_1_veri = yazmac_obegi[islenecek_buyruk[19:15]];
                    sonuc_yazmac = islenecek_buyruk[11:7];
                    
                    islem_kodu = islenecek_buyruk[14:12];
                    if(islem_kodu == 3'b000)
                    begin
                        islem_kodu = islenecek_buyruk[31:29];
                    end
                end

                01101:  //LUI
                begin
                    anlik_deger = islenecek_buyruk[31:12] << 12;
                
                    sonuc_yazmac = islenecek_buyruk[11:7];
                end

                11000:  //BEQ
                begin
                    anlik_deger[12] = islenecek_buyruk[31];
                    anlik_deger[10:5] = islenecek_buyruk[30:25];
                    anlik_deger[4:1] = islenecek_buyruk[11:8];
                    anlik_deger[11] = islenecek_buyruk[7];
                    anlik_deger[0] = 0;
                    if(anlik_deger[12] == 1'b1)
                        anlik_deger[31:13] = 19'b1_111_111_111_111_111_111;
                    else
                        anlik_deger[31:13] = 19'b0_000_000_000_000_000_000;

                    kaynak_yazmac_2_veri = yazmac_obegi[islenecek_buyruk[24:20]];
                    kaynak_yazmac_1_veri = yazmac_obegi[islenecek_buyruk[19:15]];
                end

                11001:  //JALR
                begin
                    //12 bit deger isaretle 32 bit oluyor.
                    anlik_deger = islenecek_buyruk[31:20];
                    if(anlik_deger[11] == 1'b1)
                        anlik_deger[31:12] = 20'b11_111_111_111_111_111_111;
                    else
                        anlik_deger[31:12] = 20'b00_000_000_000_000_000_000;

                    kaynak_yazmac_1_veri = yazmac_obegi[islenecek_buyruk[19:15]];
                    sonuc_yazmac = islenecek_buyruk[11:7];
                end

                11011:  //JAL
                begin
                    anlik_deger2[20] = islenecek_buyruk[31];
                    anlik_deger2[10:1] = islenecek_buyruk[30:21];
                    anlik_deger2[11] = islenecek_buyruk[20];
                    anlik_deger2[19:12] = islenecek_buyruk[19:12];
                    anlik_deger2[0] = 0;
                    if(anlik_deger[20] == 1'b1)
                        anlik_deger[31:21] = 11'b11_111_111_111;
                    else
                        anlik_deger[31:21] = 11'b00_000_000_000;

                    kaynak_yazmac_2_veri = yazmac_obegi[islenecek_buyruk[24:20]];
                    kaynak_yazmac_1_veri = yazmac_obegi[islenecek_buyruk[19:15]];
                end
            endcase
            ilerle_cmb = 1;
            simdiki_asama_ns = YURUTGERIYAZ;
        end
        
        YURUTGERIYAZ:
        begin
            case(islenecek_buyruk[6:2])
                00000:  //LW
                begin
                    bellek_veri_adres_ns = kaynak_yazmac_1_veri + anlik_deger;
                    yazmac_obegi[sonuc_yazmac] = bellek_oku_veri;
                end

                00100: yazmac_obegi[sonuc_yazmac] = kaynak_yazmac_1_veri + anlik_deger;  //ADDI

                00101:  //AUIPC
                begin
                    yazmac_obegi[sonuc_yazmac] = ps_r - 4 +  anlik_deger;
                end
                
                01000:  //SW
                begin
                    bellek_yaz_ns = 1;  //TODO: 0 yapmayi unutma.
                    bellek_veri_adres_ns = kaynak_yazmac_1_veri + anlik_deger;
                    bellek_yaz_veri_ns = kaynak_yazmac_2_veri;
                    //TODO: Eger ilerleme_cb = 1 olursa bellek_yaz_ns 0 olsun.
                    //TODO: Adres de ps_r olsun.
                end
                
                01100:  //AMB buyruklari
                begin
                    case(islem_kodu)
                        000: yazmac_obegi[sonuc_yazmac] = kaynak_yazmac_1_veri + kaynak_yazmac_2_veri;  //ADD
                        010: yazmac_obegi[sonuc_yazmac] = kaynak_yazmac_1_veri - kaynak_yazmac_2_veri;  //SUB
                        100: yazmac_obegi[sonuc_yazmac] = kaynak_yazmac_1_veri ^ kaynak_yazmac_2_veri;  //XOR
                        110: yazmac_obegi[sonuc_yazmac] = kaynak_yazmac_1_veri | kaynak_yazmac_2_veri;  //OR
                        111: yazmac_obegi[sonuc_yazmac] = kaynak_yazmac_1_veri & kaynak_yazmac_2_veri;  //AND
                    endcase
                end

                01101: yazmac_obegi[sonuc_yazmac] = anlik_deger;    //LUI

                11000:  //BEQ
                begin
                    if(kaynak_yazmac_1_veri == kaynak_yazmac_2_veri)
                        ps_ns = ps_r - 4 + anlik_deger;
                end

                11001:  //JALR
                begin
                    ps_ns = anlik_deger + kaynak_yazmac_1_veri;
                    ps_ns[0] = 0;

                    yazmac_obegi[sonuc_yazmac] = ps_r;
                end

                11011:  //JAL
                begin
                    ps_ns = ps_r - 4 + anlik_deger;

                    yazmac_obegi[sonuc_yazmac] = ps_r;
                end
            endcase
            //simdiki_asama_ns = GETIR;
        end

        //TODO: cozulen mikroislemlerle gore hangi islemlerin yapilacagini da ilet. 
    
    endcase
end

//TODO: bu always blogunu her buyruk icin uygun hale getir.
always @(posedge clk) begin
    if (rst) begin
        ps_r <= `BELLEK_ADRES;
        simdiki_asama_r <= GETIR;
        bellek_yaz_ns = 1'b0;
        bellek_yaz_veri_ns = 32'd0;
    end
    else begin
        if (ilerle_cmb) begin
            simdiki_asama_r <= simdiki_asama_ns;
        end

        ps_r <= ps_ns;  //TODO ps_ns ya da bellek_yaz_ns baglansin.
        //bellek_adres_r <= bellek_veri_adres_ns;
        bellek_yaz_r <= bellek_yaz_ns;
        bellek_yaz_veri_r <= bellek_yaz_veri_ns;
    end
end

assign bellek_adres = ps_r;
assign bellek_yaz_veri = bellek_yaz_veri_r;
assign bellek_yaz = bellek_yaz_r;

endmodule
