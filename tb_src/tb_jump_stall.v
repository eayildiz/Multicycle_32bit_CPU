`timescale 1ns / 1ps

module tb_jump_stall ();

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
   integer range;
   initial begin
      stall_ctr = 0;
      rst_r = 1'b1;
      score = 0;
      @(posedge clk_r);

      for (range = 0; range < 20480; range = range + 1) begin
         bellek_yaz(BELLEK_ADRES + range, 32'h0);
      end

      // BUYRUKLAR
      bellek_yaz(32'h8000_0000, 32'h40208063);  // beq x1, x2, 1024

      score = 0;
      repeat (10) @(posedge clk_r);
      #2;  // 10 cevrim reset
      rst_r = 1'b0;

      islemci.yazmac_obegi[1] = 32'h0000_0fff;
      islemci.yazmac_obegi[2] = -32'h0000_0fff;
      islemci.yazmac_obegi[3] = 32'h0000_0fff;
      islemci.yazmac_obegi[4] = 32'h8000_1200;

      buyruk_kontrol(1);
      if (islemci_bellek_adres !== 32'h8000_0004) begin
         $display("[ERR-1] YANLIS ADRES expected: 8000_0004 actual: %h", islemci_bellek_adres);
      end else score = score + 8;

      rst_r = 1'b1;

      bellek_yaz(32'h8000_0000, 32'h00000013);  // addi x0, x0, 0 (nop)
      bellek_yaz(32'h8000_0004, 32'h00308863);  // beq x1, x3, 16
      repeat (10) @(posedge clk_r);
      #2;
      rst_r = 1'b0;

      buyruk_kontrol(2);
      if (islemci_bellek_adres !== 32'h8000_0022) begin
         $display("[ERR-2] YANLIS ADRES expected: 8000_0022 actual: %h", islemci_bellek_adres);
      end else score = score + 4;

      rst_r = 1'b1;

      bellek_yaz(32'h8000_0000, 32'h00000013);  // addi x0, x0, 0 (nop)
      bellek_yaz(32'h8000_0004, 32'h00000013);  // addi x0, x0, 0 (nop)
      bellek_yaz(32'h8000_0008, 32'h00000013);  // addi x0, x0, 0 (nop)
      bellek_yaz(32'h8000_000c, 32'h00000013);  // addi x0, x0, 0 (nop)
      bellek_yaz(32'h8000_0010, 32'hfe308ee3);  // beq x1, x3, -4
      repeat (10) @(posedge clk_r);
      #2;
      rst_r = 1'b0;

      buyruk_kontrol(5);
      if (islemci_bellek_adres !== 32'h8000_0008) begin
         $display("[ERR-3] YANLIS ADRES expected: 8000_0008 actual: %h", islemci_bellek_adres);
      end else score = score + 4;

      if (score === 16) score = score - 1;

      rst_r = 1'b1;

      bellek_yaz(32'h8000_0000, 32'h200002ef);  // jal x5, 512
      bellek_yaz(32'h8000_0004, 32'h0);
      repeat (10) @(posedge clk_r);
      #2;
      rst_r = 1'b0;

      buyruk_kontrol(1);
      if (islemci_bellek_adres !== 32'h8000_0400) begin
         $display("[ERR-4] YANLIS ADRES expected: 8000_0400 actual: %h", islemci_bellek_adres);
      end else score = score + 5;

      rst_r = 1'b1;

      bellek_yaz(32'h8000_0000, 32'h200202e7);  // jalr x5, 512(x4)
      repeat (10) @(posedge clk_r);
      #2;
      rst_r = 1'b0;

      buyruk_kontrol(1);
      if (islemci_bellek_adres !== 32'h8000_1400) begin
         $display("[ERR-5] YANLIS ADRES expected: 8000_1400 actual: %h", islemci_bellek_adres);
      end else score = score + 5;

      $display("[INFO] Result:%0d", score);
      $finish;
   end

   // Islemcide buyruk_sayisi kadar buyruk yurutulmesini izler ve asama sirasini kontrol eder.
   task buyruk_kontrol(input [31:0] buyruk_sayisi);
      integer counter;
      begin
         for (counter = 0; counter < buyruk_sayisi; counter = counter + 1) begin
            while (!islemci.ilerle_cmb) @(posedge clk_r) #2;
            asama_kontrol(islemci.GETIR);
            @(posedge clk_r) #2;
            while (!islemci.ilerle_cmb) @(posedge clk_r) #2;
            asama_kontrol(islemci.COZYAZMACOKU);
            @(posedge clk_r) #2;
            while (!islemci.ilerle_cmb) @(posedge clk_r) #2;
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
