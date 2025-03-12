`timescale 1ns / 1ps

module tb_immediate_stall ();

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

   integer score;
   localparam MAX_CYCLES = 100;
   integer stall_ctr;
   initial begin
      stall_ctr = 0;
      rst_r = 1'b1;

      // Race condition engellemek icin sistem 1 cevrim calistirilir
      @(posedge clk_r);  // reset sinyali aktif oldugu icin degisiklik olusmaz

      score = 0;
      // BUYRUKLAR
      bellek_yaz('h8000_0000, 32'haae00893);  // addi x17, x0, -1362
      bellek_yaz('h8000_0004, 32'h17200e93);  // addi x29, x0, 370

      bellek_yaz('h8000_0008, 32'h52ae9637);  // lui x12, 338665
      bellek_yaz('h8000_000c, 32'hac7404b7);  // lui x9, -342208

      bellek_yaz('h8000_0010, 32'hab7b6217);  // auipc x4, -346186
      bellek_yaz('h8000_0014, 32'h56eca197);  // auipc x3, 356042

      repeat (10) @(posedge clk_r);
      #2;  // 10 cevrim reset
      rst_r = 1'b0;

      buyruk_kontrol(2);  // 2 buyruk yurut
      if (yazmac_oku(17) !== -1362) begin
         $display("[ERR] x17 expected: -1362 actual: %0d", yazmac_oku(17));
      end else score = score + 1;

      if (yazmac_oku(29) !== 370) begin
         $display("[ERR] x29 expected: 370 actual: %0d", yazmac_oku(29));
      end else score = score + 1;

      buyruk_kontrol(2);  // 2 buyruk yurut
      if (yazmac_oku(12) !== 338665 << 12) begin
         $display("[ERR] x12 expected: 338665 << 12 actual: %0d", yazmac_oku(12));
      end else score = score + 1;

      if (yazmac_oku(9) !== -(342208 << 12)) begin
         $display("[ERR] x9 expected: -342208 << 12 actual: %0d", yazmac_oku(9));
      end else score = score + 1;

      buyruk_kontrol(2);  // 2 buyruk yurut
      if (yazmac_oku(4) !== 32'h8000_0010 + $signed({{-20'd346186},{12'd0}})) begin
         $display("[ERR] x4 expected: %d actual: %0d",
         (32'h8000_0010 + $signed({{-20'd346186},{12'd0}})), yazmac_oku(4));
      end else score = score + 1;

      if (yazmac_oku(3) !== 32'h8000_0014 + $signed({{20'd356042}, {12'd0}})) begin
         $display("[ERR] x3 expected: %d actual: %0d",
         (32'h8000_0014 + $signed({{20'd356042}, {12'd0}})), yazmac_oku(3));
      end else score = score + 1;

      if (score > 5) begin
         score = score - 1;
      end
      score = score * 2;

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
