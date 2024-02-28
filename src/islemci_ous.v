`timescale 1ns/1ps

`define BELLEK_ADRES    32'h8000_0000
`define VERI_BIT        32
`define ADRES_BIT       32
`define YAZMAC_SAYISI   32

module islemci_ous (
    input                       clk,
    input                       rst,
    output  [`ADRES_BIT-1:0]    bellek_adres,
    input   [`VERI_BIT-1:0]     bellek_oku_veri,
    output  [`VERI_BIT-1:0]     bellek_yaz_veri,
    output                      bellek_yaz
);

//anabellek anabellek_(clk, bellek_adres, bellek_oku_veri, bellek_yaz_veri, bellek_yaz);

localparam GETIR        = 2'd0;
localparam COZYAZMACOKU = 2'd1;
localparam YURUTGERIYAZ = 2'd2;

reg [1:0] simdiki_asama_ns;
reg [1:0] simdiki_asama_r;
reg ilerle_cmb;

reg [`VERI_BIT-1:0] yazmac_obegi [0:`YAZMAC_SAYISI-1];
reg [`VERI_BIT-1:0] islenecek_buyruk;
reg [`ADRES_BIT-1:0] ps_ns;
reg [`ADRES_BIT-1:0] ps_r;

reg [`VERI_BIT-1:0] bellek_veri_adres_ns = `VERI_BIT'd96;
reg [`VERI_BIT-1:0] bellek_yaz_veri_ns = `VERI_BIT'd96;
reg bellek_yaz_ns = 1'b0;

reg [`VERI_BIT-1:0] bellek_adres_r;
reg [`VERI_BIT-1:0] bellek_yaz_veri_r;
reg bellek_yaz_r;

//Mikroislemler yazmaclari
reg [`VERI_BIT-1:0] anlik_deger;
reg [`VERI_BIT-1:0] kaynak_yazmac_1_veri;
reg [`VERI_BIT-1:0] kaynak_yazmac_2_veri;
reg [4:0] sonuc_yazmac;
reg [2:0] islem_kodu;   //AMB icin detaylar

//Kirby Siralama(KS) & Doge Store(DS) flip floplari
reg [4:0] kaynak_yazmac = 5'd1;

reg [4:0] uzunluk = 5'd0;

reg [4:0] dongu_sirasi_ns = 5'd0;
reg [4:0] yazilan_deger_sayisi_ns = 5'd0;
reg [`VERI_BIT-1:0] hedef_adres_ns = `VERI_BIT'h8000_0000;

reg [4:0] dongu_sirasi_r = 5'd0;
reg [4:0] yazilan_deger_sayisi_r = 5'd0;
reg [`VERI_BIT-1:0] hedef_adres_r = `VERI_BIT'h8000_0000;

initial begin:Yazmac_doldurma
    integer i;
    for (i = 0; i < `YAZMAC_SAYISI; i = i + 1)
    begin
        islemci_ous.yazmac_obegi[i] <= `VERI_BIT'd0;
    end
end


always @ * begin
    bellek_yaz_ns = 1'b0;
    //$display("%d asamasinda always triggered", simdiki_asama_r, simdiki_asama_r);
    
    case(simdiki_asama_r)
        
        GETIR:
        begin
            islenecek_buyruk = bellek_oku_veri;  //Islenmesi gereken buyrugun program sayaci bellege gonderilir ve gelenbuyruk bir sonraki aşama için kayıt edilir. 
            ps_ns = ps_r + `VERI_BIT'd4;   //Getir asamasi istek yapildiktan sonra saatin yukselen kenarinda program sayacini gunceller.
            //$display("%d asamasinda Islenecek buyruk: %b", simdiki_asama_r, islenecek_buyruk);
            //$display("%d asamasinda Program sayaci: %b", simdiki_asama_r, ps_ns);
            simdiki_asama_ns = COZYAZMACOKU;
            ilerle_cmb = 1'b1;
        end
        
        /*Olasi iyilestirmeler
        * rs1 icin sondan 3. bit 0 veya buyruk 1100111.
        * 1. bit 1 ise dallanma vardir.
        * Ayni islemleri yapanları birleştirmeyi dusun.
        */
        COZYAZMACOKU:
        begin
            //$display("%d asamasinda Islenecek buyruk: %b", simdiki_asama_r, islenecek_buyruk);
            case(islenecek_buyruk[6:2])
                5'b00_000:  //LW
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
                
                5'b00_100:  //ADDI
                begin
                    //12 bit deger isaretle 32 bit oluyor.
                    anlik_deger = islenecek_buyruk[31:20];
                    if(anlik_deger[11] == 1'b1)
                        anlik_deger[31:12] = 20'b11_111_111_111_111_111_111;
                    else
                        anlik_deger[31:12] = 12'b00_000_000_000_000_000_000;

                    kaynak_yazmac_1_veri = yazmac_obegi[islenecek_buyruk[19:15]];
                    sonuc_yazmac = islenecek_buyruk[11:7];
                    //$display("ADDI islemi kaynaklari: yazmac %b ; flip flop %b", yazmac_obegi[islenecek_buyruk[19:15]], kaynak_yazmac_1_veri);
                end

                5'b00_101:  //AUIPC
                begin
                    anlik_deger = islenecek_buyruk[31:12] << 12;

                    sonuc_yazmac = islenecek_buyruk[11:7];
                end

                5'b01_000:  //SW
                begin
                    //12 bit deger isaretle 32 bit oluyor.
                    anlik_deger[11:5] = islenecek_buyruk[31:25];
                    anlik_deger[4:0] = islenecek_buyruk[11:7];
                    if(anlik_deger[11] == 1'b1)
                        anlik_deger[31:12] = 20'b11_111_111_111_111_111_111;
                    else
                        anlik_deger[31:12] = 20'b00_000_000_000_000_000_000;

                    kaynak_yazmac_2_veri = yazmac_obegi[islenecek_buyruk[24:20]];
                    kaynak_yazmac_1_veri = yazmac_obegi[islenecek_buyruk[19:15]];
                end
                
                5'b01_100:  //AMB buyruklari
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

                5'b01_101:  //LUI
                begin
                    anlik_deger = islenecek_buyruk[31:12] << 12;
                
                    sonuc_yazmac = islenecek_buyruk[11:7];
                end

                5'b11_000:  //BEQ
                begin
                    //13 bit deger isaretle 32 bit oluyor.
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

                5'b11_001:  //JALR
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

                5'b11_011:  //JAL
                begin
                    //20 bit deger isaretle 32 bit oluyor.
                    anlik_deger[20] = islenecek_buyruk[31];
                    anlik_deger[10:1] = islenecek_buyruk[30:21];
                    anlik_deger[11] = islenecek_buyruk[20];
                    anlik_deger[19:12] = islenecek_buyruk[19:12];
                    anlik_deger[0] = 1'b0;
                    if(anlik_deger[20] == 1'b1)
                        anlik_deger[31:21] = 11'b11_111_111_111;
                    else
                        anlik_deger[31:21] = 11'b00_000_000_000;

                    kaynak_yazmac_2_veri = yazmac_obegi[islenecek_buyruk[24:20]];
                    kaynak_yazmac_1_veri = yazmac_obegi[islenecek_buyruk[19:15]];
                end

                5'b11_100:  //KS & DS
                begin
                    uzunluk = islenecek_buyruk[24:20];
                    kaynak_yazmac = islenecek_buyruk[19:15];
                    sonuc_yazmac = islenecek_buyruk[11:7];                  //Sadece KS icin.
                    hedef_adres_ns = yazmac_obegi[islenecek_buyruk[11:7]];  //Sadece DS icin.

                    islem_kodu = islenecek_buyruk[14:12];

                    dongu_sirasi_ns = 5'd0;
                    yazilan_deger_sayisi_ns = 5'd0;
                end

                default:
                begin
                    $display("COZYAZMACOKU Hata");
                    anlik_deger = 32'd0;
                    islem_kodu = 3'd0;
                    kaynak_yazmac_1_veri = 32'd0;
                    kaynak_yazmac_2_veri = 32'd0;
                    sonuc_yazmac = 5'd0;
                end
            endcase
            simdiki_asama_ns = YURUTGERIYAZ;
            ilerle_cmb = 1'b1;
        end
    endcase
        end

//Bellek adres guncelleme flip floplari
reg bellek_veri_erisme_adresi_guncel_ns = 1'b0;
reg bellek_veri_erisme_adresi_guncel_r = 1'b0;

always @(*)
begin
    if(simdiki_asama_r == YURUTGERIYAZ)
    begin
        bellek_yaz_ns = 1'b0;
        ilerle_cmb = 1'b0;
        //$display("YURUTGERIYAZ Modu, ilerle_cmb: %b", ilerle_cmb);
        case(islenecek_buyruk[6:2])

            5'b00_000:  //LW
            begin
                if(!bellek_veri_erisme_adresi_guncel_r)
                begin
                    bellek_veri_adres_ns = kaynak_yazmac_1_veri + anlik_deger;
                    bellek_veri_erisme_adresi_guncel_ns = 1'b1;
                end
                else
                begin
                    yazmac_obegi[sonuc_yazmac] = bellek_oku_veri;
                    bellek_veri_erisme_adresi_guncel_ns = 1'b0;
                    simdiki_asama_ns = GETIR;
                    ilerle_cmb = 1'b1;
                end
                //$display("LW islemi kaynaklari: %b ; %b", kaynak_yazmac_1_veri, anlik_deger);
                //$display("LW islemi Sonuc yazmaci %0d : %b", sonuc_yazmac, yazmac_obegi[sonuc_yazmac]);
            end
                        
            5'b00_100:  //ADDI
            begin
                yazmac_obegi[sonuc_yazmac] = kaynak_yazmac_1_veri + anlik_deger;

                simdiki_asama_ns = GETIR;
                ilerle_cmb = 1'b1;
                //$display("ADDI islemi kaynaklari: %b ; %b", kaynak_yazmac_1_veri, anlik_deger);
                //$display("ADDI islemi Sonuc yazmaci %0d : %b", sonuc_yazmac, yazmac_obegi[sonuc_yazmac]);
            end

            5'b00_101:  //AUIPC
            begin
                yazmac_obegi[sonuc_yazmac] = ps_r - `VERI_BIT'd4 +  anlik_deger;

                simdiki_asama_ns = GETIR;
                ilerle_cmb = 1'b1;
                //$display("AUIPC islemi Sonuc yazmaci %0d : %b", sonuc_yazmac, yazmac_obegi[sonuc_yazmac]);
            end
                
            5'b01_000:  //SW
            begin
                if(!bellek_veri_erisme_adresi_guncel_r)
                begin
                    bellek_yaz_ns = 1'b1;
                    bellek_veri_adres_ns = kaynak_yazmac_1_veri + anlik_deger;
                    bellek_yaz_veri_ns = kaynak_yazmac_2_veri;

                    bellek_veri_erisme_adresi_guncel_ns = 1'b1;
                    //$display("SW adresi: %h", bellek_veri_adres_ns);
                    //$display("SW yazilan deger: %h", bellek_yaz_veri_ns);
                    //$display("SW komutu, ilerle_cmb: %b", ilerle_cmb);
                end
                else
                begin
                    simdiki_asama_ns = GETIR;
                    ilerle_cmb = 1'b1;
                    
                    bellek_veri_erisme_adresi_guncel_ns = 1'b0;
                    //$display("SW komutu, ilerle_cmb: %b", ilerle_cmb);
                end
            end
                
            5'b01_100:  //AMB buyruklari
            begin
                case(islem_kodu)
                    3'b000: yazmac_obegi[sonuc_yazmac] = kaynak_yazmac_1_veri + kaynak_yazmac_2_veri;  //ADD
                    3'b010: yazmac_obegi[sonuc_yazmac] = kaynak_yazmac_1_veri - kaynak_yazmac_2_veri;  //SUB
                    3'b100: yazmac_obegi[sonuc_yazmac] = kaynak_yazmac_1_veri ^ kaynak_yazmac_2_veri;  //XOR
                    3'b110: yazmac_obegi[sonuc_yazmac] = kaynak_yazmac_1_veri | kaynak_yazmac_2_veri;  //OR
                    3'b111: yazmac_obegi[sonuc_yazmac] = kaynak_yazmac_1_veri & kaynak_yazmac_2_veri;  //AND
                endcase

                simdiki_asama_ns = GETIR;
                ilerle_cmb = 1'b1;
                //$display("AMB islemi kaynaklari: %b ; %b", kaynak_yazmac_1_veri, kaynak_yazmac_2_veri);
                //$display("AMB islemi Sonuc yazmaci %0d : %b", sonuc_yazmac, yazmac_obegi[sonuc_yazmac]);
            end

            5'b01_101:  //LUI
            begin
                yazmac_obegi[sonuc_yazmac] = anlik_deger;
                
                simdiki_asama_ns = GETIR;
                ilerle_cmb = 1'b1;
                //$display("LUI islemi Sonuc yazmaci %0d : %b", sonuc_yazmac, yazmac_obegi[sonuc_yazmac]);
            end
            
            5'b11_000:  //BEQ
            begin
                if(kaynak_yazmac_1_veri == kaynak_yazmac_2_veri)
                    ps_ns = ps_r - `VERI_BIT'd4 + anlik_deger;
                
                simdiki_asama_ns = GETIR;
                ilerle_cmb = 1'b1;
            end

            5'b11_001:  //JALR
            begin
                ps_ns = anlik_deger + kaynak_yazmac_1_veri;
                ps_ns[0] = 1'b0;

                yazmac_obegi[sonuc_yazmac] = ps_r;
            
                simdiki_asama_ns = GETIR;
                ilerle_cmb = 1'b1;
                //$display("JALR islemi Sonuc yazmaci %0d : %b", sonuc_yazmac, yazmac_obegi[sonuc_yazmac]);
            end

            5'b11_011:  //JAL
            begin
                ps_ns = ps_r - `VERI_BIT'd4 + anlik_deger;

                yazmac_obegi[sonuc_yazmac] = ps_r;
                
                simdiki_asama_ns = GETIR;
                ilerle_cmb = 1'b1;
                //$display("JAL islemi Sonuc yazmaci %0d : %b", sonuc_yazmac, yazmac_obegi[sonuc_yazmac]);
            end

            5'b11_100:  //KS & DS
            begin
                case(islem_kodu)
                    3'b001: //KS
                    begin
                        if(dongu_sirasi_r < uzunluk)
                        begin
                            if(dongu_sirasi_r == 5'd0)
                            begin
                                yazmac_obegi[sonuc_yazmac] = yazmac_obegi[kaynak_yazmac];
                                yazilan_deger_sayisi_ns = yazilan_deger_sayisi_r + 1;
                            end
                            else if(yazmac_obegi[kaynak_yazmac + dongu_sirasi_r] >= yazmac_obegi[kaynak_yazmac + dongu_sirasi_r - 1])
                            begin
                                yazmac_obegi[sonuc_yazmac + yazilan_deger_sayisi_r] = yazmac_obegi[kaynak_yazmac + dongu_sirasi_r];
                                yazilan_deger_sayisi_ns = yazilan_deger_sayisi_r + 1;
                            end
                            dongu_sirasi_ns = dongu_sirasi_r + 1;
                        end
                        else
                        begin
                            simdiki_asama_ns = GETIR;
                            ilerle_cmb = 1'b1;
                        end
                    end
                    3'b010: //DS
                    begin
                        if(dongu_sirasi_r < uzunluk)
                        begin
                            if(!bellek_veri_erisme_adresi_guncel_r) //Degerleri yazmak icin kablolara yollama.
                            begin
                                bellek_yaz_ns = 1'b1;
                                bellek_veri_adres_ns = hedef_adres_r;
                                bellek_yaz_veri_ns = yazmac_obegi[kaynak_yazmac + dongu_sirasi_r];

                                bellek_veri_erisme_adresi_guncel_ns = 1'b1;
                                //$display("DS adresi: %h", bellek_veri_adres_ns);
                                //$display("DS yazilan deger: %h", bellek_yaz_veri_ns);
                                //$display("DS komutu, ilerle_cmb: %b", ilerle_cmb);
                            end
                            else    //Adres guncellemesi
                            begin
                                bellek_yaz_ns = 1'b0;
                                hedef_adres_ns = hedef_adres_r + 32'd4;
                                dongu_sirasi_ns = dongu_sirasi_r + 1;
                                
                                bellek_veri_erisme_adresi_guncel_ns = 1'b0;
                                //$display("DS komutu, ilerle_cmb: %b", ilerle_cmb);
                            end
                        end
                        else
                        begin
                            simdiki_asama_ns = GETIR;
                            ilerle_cmb = 1'b1;
                        end
                    end
                endcase
            end

            default:
            begin
                $display("YURUTGERIYAZ Hata");
                simdiki_asama_ns = GETIR;
                ilerle_cmb = 1'b1;
            end
        endcase
    end
end

always @(posedge clk) begin
    //$display("Saat vurdu");
    if (rst)
    begin
        ps_r <= `BELLEK_ADRES;
        simdiki_asama_r <= GETIR;
        bellek_yaz_r <= 1'b0;
        bellek_yaz_veri_r <= 32'd0;
    end
    else
    begin
        if (ilerle_cmb)
        begin
            simdiki_asama_r <= simdiki_asama_ns;
            //$display("%0d asamasinda asama degisti.", simdiki_asama_ns);
            //$display("ilerle_cmb: %b", ilerle_cmb);
        end
        
        //$display("%0d asamasinda ilerle_cmb: %d degerinde", simdiki_asama_ns, ilerle_cmb);
        if(simdiki_asama_ns == GETIR)
        begin
            ps_r <= ps_ns;
            //$display("%0d asamasinda Program Sayaci: %h", simdiki_asama_ns, ps_ns);
        end
        else
        begin
            ps_r <= bellek_veri_adres_ns;
            //$display("%0d asamasinda Bellek adresi: %h", simdiki_asama_ns, bellek_veri_adres_ns);
        end

        bellek_yaz_r <= bellek_yaz_ns;
        bellek_yaz_veri_r <= bellek_yaz_veri_ns;
        bellek_veri_erisme_adresi_guncel_r <= bellek_veri_erisme_adresi_guncel_ns;
        //$display("%0d asamasinda Bellek veri: %h", simdiki_asama_ns, bellek_yaz_veri_ns);

        //KS & DS
        dongu_sirasi_r <= dongu_sirasi_ns;
        yazilan_deger_sayisi_r <= yazilan_deger_sayisi_ns;
        hedef_adres_r <= hedef_adres_ns;
    end
end

assign bellek_adres = ps_r;
assign bellek_yaz_veri = bellek_yaz_veri_r;
assign bellek_yaz = bellek_yaz_r;

endmodule
