`timescale 1ns / 1ps

module tb_memory ();

   localparam BELLEK_ADRES = 32'h8000_0000;
   localparam ADRES_BIT = 32;
   localparam VERI_BIT = 32;

   reg clk_r;
   reg rst_r;

   wire [ADRES_BIT-1:0] islemci_bellek_adres;
   wire [VERI_BIT-1:0] islemci_bellek_oku_veri;
   wire [VERI_BIT-1:0] islemci_bellek_yaz_veri;
   wire islemci_bellek_yaz;

   anabellek anabellek (
      .clk(clk_r),
      .adres(islemci_bellek_adres),
      .oku_veri(islemci_bellek_oku_veri),
      .yaz_veri(islemci_bellek_yaz_veri),
      .yaz_gecerli(islemci_bellek_yaz)
   );

   islemci islemci (
      .clk(clk_r),
      .rst(rst_r),
      .bellek_adres(islemci_bellek_adres),
      .bellek_oku_veri(islemci_bellek_oku_veri),
      .bellek_yaz_veri(islemci_bellek_yaz_veri),
      .bellek_yaz(islemci_bellek_yaz)
   );

   always begin
      clk_r = 1'b0;
      #5;
      clk_r = 1'b1;
      #5;
   end

   localparam MAX_CYCLES = 100;
   integer stall_ctr;
   integer score;
   integer score2;
   integer score2_inc;
   initial begin
      stall_ctr = 0;
      rst_r = 1'b1;
      score = 0;
      score2 = 0;
      score2_inc = 1;
      @(posedge clk_r);

      // BUYRUKLAR
      bellek_yaz(32'h8000_0000, 32'h00022a03);  // lw x20, 0(x4)
      bellek_yaz(32'h8000_0004, 32'h00422a83);  // lw x21, 4(x4)
      bellek_yaz(32'h8000_0008, 32'h00822b03);  // lw x22, 8(x4)
      bellek_yaz(32'h8000_000c, 32'h00c22b83);  // lw x23, 12(x4)
      bellek_yaz(32'h8000_0010, 32'h01022c03);  // lw x24, 16(x4)

      bellek_yaz(32'h8000_0200, 32'h200);
      bellek_yaz(32'h8000_0204, 32'h400);
      bellek_yaz(32'h8000_0208, 32'h800);
      bellek_yaz(32'h8000_020c, 32'hc00);
      bellek_yaz(32'h8000_0210, 32'h1000);

      bellek_yaz(32'h8000_0014, 32'h0002ac83);  // lw x25, 0(x5)
      bellek_yaz(32'h8000_0018, 32'hffc2ad03);  // lw x26, -4(x5)
      bellek_yaz(32'h8000_001c, 32'hff82ad83);  // lw x27, -8(x5)
      bellek_yaz(32'h8000_0020, 32'hff42ae03);  // lw x28, -12(x5)
      bellek_yaz(32'h8000_0024, 32'hff02ae83);  // lw x29, -16(x5)

      bellek_yaz(32'h8000_0224, 32'h2000);
      bellek_yaz(32'h8000_0220, 32'h4000);
      bellek_yaz(32'h8000_021c, 32'h8000);
      bellek_yaz(32'h8000_0218, 32'hc000);
      bellek_yaz(32'h8000_0214, 32'h10000);

      bellek_yaz(32'h8000_0028, 32'h00832023);  //sw x8, 0(x6)
      bellek_yaz(32'h8000_002c, 32'h00932223);  //sw x9, 4(x6)
      bellek_yaz(32'h8000_0030, 32'h00a32423);  //sw x10, 8(x6)
      bellek_yaz(32'h8000_0034, 32'h00b32623);  //sw x11, 12(x6)
      bellek_yaz(32'h8000_0038, 32'h00c32823);  //sw x12, 16(x6)

      bellek_yaz(32'h8000_003c, 32'h00d3a023);  //sw x13, 0(x7)
      bellek_yaz(32'h8000_0040, 32'hfee3ae23);  //sw x14, -4(x7)
      bellek_yaz(32'h8000_0044, 32'hfef3ac23);  //sw x15, -8(x7)
      bellek_yaz(32'h8000_0048, 32'hff03aa23);  //sw x16, -12(x7)
      bellek_yaz(32'h8000_004c, 32'hff13a823);  //sw x17, -16(x7)

      score = 0;
      repeat (10) @(posedge clk_r);
      #2;  // 10 cevrim reset
      rst_r = 1'b0;

      islemci.yazmac_obegi[20] = 32'hffff_ffff;
      islemci.yazmac_obegi[4] = 32'h8000_0200;
      islemci.yazmac_obegi[5] = 32'h8000_0224;
      islemci.yazmac_obegi[6] = 32'h8000_0300;
      islemci.yazmac_obegi[7] = 32'h8000_0410;

      islemci.yazmac_obegi[8] = -32'hffccff;
      islemci.yazmac_obegi[9] = -32'hfccccf;
      islemci.yazmac_obegi[10] = -32'hcfccfc;
      islemci.yazmac_obegi[11] = -32'hcccccc;
      islemci.yazmac_obegi[12] = -32'hccffcc;

      islemci.yazmac_obegi[13] = 32'hdbdbdb;
      islemci.yazmac_obegi[14] = 32'hbdbdbd;
      islemci.yazmac_obegi[15] = 32'hddbbdd;
      islemci.yazmac_obegi[16] = 32'hbbddbb;
      islemci.yazmac_obegi[17] = 32'hdddddd;

      buyruk_kontrol(5);
      if (islemci.yazmac_obegi[20] !== bellek_oku(yazmac_oku(4))) begin
         $display("[ERR] x20 expected: 200 actual: %0x", islemci.yazmac_obegi[20]);
      end else score = score + 2;
      if (islemci.yazmac_obegi[21] !== bellek_oku(yazmac_oku(4) + 4)) begin
         $display("[ERR] x21 expected: 400 actual: %0x", islemci.yazmac_obegi[21]);
      end else score = score + 2;
      if (islemci.yazmac_obegi[22] !== bellek_oku(yazmac_oku(4) + 8)) begin
         $display("[ERR] x22 expected: 800 actual: %0x", islemci.yazmac_obegi[22]);
      end else score = score + 2;
      if (islemci.yazmac_obegi[23] !== bellek_oku(yazmac_oku(4) + 12)) begin
         $display("[ERR] x23 expected: c00 actual: %0x", islemci.yazmac_obegi[23]);
      end else score = score + 2;
      if (islemci.yazmac_obegi[24] !== bellek_oku(yazmac_oku(4) + 16)) begin
         $display("[ERR] x24 expected: 1000 actual: %0x", islemci.yazmac_obegi[24]);
      end else score = score + 2;

      buyruk_kontrol(5);
      if (islemci.yazmac_obegi[25] !== bellek_oku(yazmac_oku(5))) begin
         $display("[ERR] x25 expected: 2000 actual: %0x", islemci.yazmac_obegi[25]);
      end else score = score + 1;
      if (islemci.yazmac_obegi[26] !== bellek_oku(yazmac_oku(5) - 4)) begin
         $display("[ERR] x26 expected: 4000 actual: %0x", islemci.yazmac_obegi[26]);
      end else score = score + 1;
      if (islemci.yazmac_obegi[27] !== bellek_oku(yazmac_oku(5) - 8)) begin
         $display("[ERR] x27 expected: 8000 actual: %0x", islemci.yazmac_obegi[27]);
      end else score = score + 1;
      if (islemci.yazmac_obegi[28] !== bellek_oku(yazmac_oku(5) - 12)) begin
         $display("[ERR] x28 expected: c000 actual: %0x", islemci.yazmac_obegi[28]);
      end else score = score + 1;
      if (islemci.yazmac_obegi[29] !== bellek_oku(yazmac_oku(5) - 16)) begin
         $display("[ERR] x29 expected: 10000 actual: %0x", islemci.yazmac_obegi[29]);
      end else score = score + 1;

      if (score <= 10) begin
         score2_inc = 2;
      end

      buyruk_kontrol(5);
      if (bellek_oku(yazmac_oku(6)) !== islemci.yazmac_obegi[8]) begin
         $display("[ERR] Memory Addr %0x value expected: %0x actual: %0x", yazmac_oku(6),
                  bellek_oku(yazmac_oku(6)), islemci.yazmac_obegi[8]);
      end else score = score + score2_inc;
      if (bellek_oku(yazmac_oku(6) + 4) !== islemci.yazmac_obegi[9]) begin
         $display("[ERR] Memory Addr %0x value expected: %0x actual: %0x", yazmac_oku(6) + 4,
                  bellek_oku(yazmac_oku(6) + 4), islemci.yazmac_obegi[9]);
      end else score = score + score2_inc;
      if (bellek_oku(yazmac_oku(6) + 8) !== islemci.yazmac_obegi[10]) begin
         $display("[ERR] Memory Addr %0x value expected: %0x actual: %0x", yazmac_oku(6) + 8,
                  bellek_oku(yazmac_oku(6) + 8), islemci.yazmac_obegi[10]);
      end else score = score + score2_inc;
      if (bellek_oku(yazmac_oku(6) + 12) !== islemci.yazmac_obegi[11]) begin
         $display("[ERR] Memory Addr %0x value expected: %0x actual: %0x", yazmac_oku(6) + 12,
                  bellek_oku(yazmac_oku(6) + 12), islemci.yazmac_obegi[11]);
      end else score = score + score2_inc;
      if (bellek_oku(yazmac_oku(6) + 16) !== islemci.yazmac_obegi[12]) begin
         $display("[ERR] Memory Addr %0x value expected: %0x actual: %0x", yazmac_oku(6) + 16,
                  bellek_oku(yazmac_oku(6) + 16), islemci.yazmac_obegi[12]);
      end else score = score + score2_inc;

      buyruk_kontrol(5);
      if (bellek_oku(yazmac_oku(7)) !== islemci.yazmac_obegi[13]) begin
         $display("[ERR] Memory Addr %0x value %0x expected: actual: %0x", yazmac_oku(7),
                  bellek_oku(yazmac_oku(7)), islemci.yazmac_obegi[13]);
      end else score = score + 1;
      if (bellek_oku(yazmac_oku(7) - 4) !== islemci.yazmac_obegi[14]) begin
         $display("[ERR] Memory Addr %0x value %0x expected: actual: %0x", yazmac_oku(7) - 4,
                  bellek_oku(yazmac_oku(7) - 4), islemci.yazmac_obegi[14]);
      end else score = score + 1;
      if (bellek_oku(yazmac_oku(7) - 8) !== islemci.yazmac_obegi[15]) begin
         $display("[ERR] Memory Addr %0x value %0x expected: actual: %0x", yazmac_oku(7) - 8,
                  bellek_oku(yazmac_oku(7) - 8), islemci.yazmac_obegi[15]);
      end else score = score + 1;
      if (bellek_oku(yazmac_oku(7) - 12) !== islemci.yazmac_obegi[16]) begin
         $display("[ERR] Memory Addr %0x value %0x expected: actual: %0x", yazmac_oku(7) - 12,
                  bellek_oku(yazmac_oku(7) - 12), islemci.yazmac_obegi[16]);
      end else score = score + 1;
      if (bellek_oku(yazmac_oku(7) - 16) !== islemci.yazmac_obegi[17]) begin
         $display("[ERR] Memory Addr %0x value %0x expected: actual: %0x", yazmac_oku(7) - 16,
                  bellek_oku(yazmac_oku(7) - 16), islemci.yazmac_obegi[17]);
      end else score = score + 1;

      $display("[INFO] Result:%0d", score);
      $finish;
   end

   // Islemcide buyruk_sayisi kadar buyruk yurutulmesini izler ve asama sirasini kontrol eder.
   task buyruk_kontrol(input [31:0] buyruk_sayisi);
      integer counter;
      begin
         for (counter = 0; counter < buyruk_sayisi; counter = counter + 1) begin
            asama_kontrol(islemci.GETIR);
            @(posedge clk_r) #2;
            asama_kontrol(islemci.COZYAZMACOKU);
            @(posedge clk_r) #2;
            asama_kontrol(islemci.YURUTGERIYAZ);
            @(posedge clk_r) #2;
         end
      end
   endtask

   task asama_kontrol(input [1:0] beklenen);
      begin
         if (islemci.simdiki_asama_r !== beklenen) begin
            $display("[ERR] YANLIS ASAMA expected: %0x actual: %0x", beklenen,
                     islemci.simdiki_asama_r);
         end
      end
   endtask

   task bellek_yaz(input [ADRES_BIT-1:0] adres, input [VERI_BIT-1:0] veri);
      begin
         anabellek.bellek[adres_satir_idx(adres)] = veri;
      end
   endtask

   function [VERI_BIT-1:0] bellek_oku(input [ADRES_BIT-1:0] adres);
      begin
         bellek_oku = anabellek.bellek[adres_satir_idx(adres)];
      end
   endfunction

   function [VERI_BIT-1:0] yazmac_oku(input integer yazmac_idx);
      begin
         yazmac_oku = islemci.yazmac_obegi[yazmac_idx];
      end
   endfunction

   // Verilen adresi bellek satir indisine donusturur.
   function integer adres_satir_idx(input [ADRES_BIT-1:0] adres);
      begin
         adres_satir_idx = (adres - BELLEK_ADRES) >> $clog2(VERI_BIT / 8);
      end
   endfunction

endmodule
