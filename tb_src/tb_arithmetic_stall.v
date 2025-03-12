`timescale 1ns / 1ps

module tb_arithmetic_stall ();

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
   initial begin
      stall_ctr = 0;
      rst_r = 1'b1;
      score = 0;
      @(posedge clk_r);

      // BUYRUKLAR
      bellek_yaz('h8000_0000, 32'h00408ab3);  // add x21, x1, x4
      bellek_yaz('h8000_0004, 32'h40408b33);  // sub x22, x1, x4
      bellek_yaz('h8000_0008, 32'h0040ebb3);  // or x23, x1, x4
      bellek_yaz('h8000_000c, 32'h0040fc33);  // and x24, x1, x4
      bellek_yaz('h8000_0010, 32'h0040ccb3);  // xor x25, x1, x4

      bellek_yaz('h8000_0014, 32'h009085b3);  // add x11, x1, x9
      bellek_yaz('h8000_0018, 32'h40908633);  // sub x12, x1, x9
      bellek_yaz('h8000_001c, 32'h0090e6b3);  // or x13, x1, x9
      bellek_yaz('h8000_0020, 32'h0090f733);  // and x14, x1, x9
      bellek_yaz('h8000_0024, 32'h0090c7b3);  // xor x15, x1, x9
      repeat (10) @(posedge clk_r);
      #2;  // 10 cevrim reset
      rst_r = 1'b0;

      islemci.yazmac_obegi[1] = 32'h0eff45cd;
      islemci.yazmac_obegi[4] = 32'hf00fff00;
      islemci.yazmac_obegi[9] = 32'h036195db;

      buyruk_kontrol(1);  // 1 buyruk yurut
      if (islemci.yazmac_obegi[21] !== islemci.yazmac_obegi[1] + islemci.yazmac_obegi[4]) begin
         $display("[ERR] ADD x21, x1, x4");
         $display("Expected: %0x, Actual: %0x", islemci.yazmac_obegi[1] + islemci.yazmac_obegi[4],
                  islemci.yazmac_obegi[21]);
      end else score = score + 1;
      buyruk_kontrol(1);  // 1 buyruk yurut
      if (islemci.yazmac_obegi[22] !== (islemci.yazmac_obegi[1] - islemci.yazmac_obegi[4])) begin
         $display("[ERR] SUB x22, x1, x4");
         $display("Expected: %0x, Actual: %0x", islemci.yazmac_obegi[1] - islemci.yazmac_obegi[4],
                  islemci.yazmac_obegi[22]);
      end else score = score + 1;
      buyruk_kontrol(1);  // 1 buyruk yurut
      if (islemci.yazmac_obegi[23] !== (islemci.yazmac_obegi[1] | islemci.yazmac_obegi[4])) begin
         $display("[ERR] OR x23, x1, x4");
         $display("Expected: %0x, Actual: %0x", islemci.yazmac_obegi[1] | islemci.yazmac_obegi[4],
                  islemci.yazmac_obegi[23]);
      end else score = score + 1;
      buyruk_kontrol(1);  // 1 buyruk yurut
      if (islemci.yazmac_obegi[24] !== (islemci.yazmac_obegi[1] & islemci.yazmac_obegi[4])) begin
         $display("[ERR] AND x24, x1, x4");
         $display("Expected: %0x, Actual: %0x", islemci.yazmac_obegi[1] & islemci.yazmac_obegi[4],
                  islemci.yazmac_obegi[24]);
      end else score = score + 1;
      buyruk_kontrol(1);  // 1 buyruk yurut
      if (islemci.yazmac_obegi[25] !== (islemci.yazmac_obegi[1] ^ islemci.yazmac_obegi[4])) begin
         $display("[ERR] XOR x25, x1, x4");
         $display("Expected: %0x, Actual: %0x", islemci.yazmac_obegi[1] ^ islemci.yazmac_obegi[4],
                  islemci.yazmac_obegi[25]);
      end else score = score + 1;

      buyruk_kontrol(1);  // 1 buyruk yurut
      if (islemci.yazmac_obegi[11] !== (islemci.yazmac_obegi[1] + islemci.yazmac_obegi[9])) begin
         $display("[ERR] ADD x11, x1, x9");
         $display("Expected: %0x, Actual: %0x", islemci.yazmac_obegi[1] + islemci.yazmac_obegi[9],
                  islemci.yazmac_obegi[11]);
      end else score = score + 1;
      buyruk_kontrol(1);  // 1 buyruk yurut
      if (islemci.yazmac_obegi[12] !== (islemci.yazmac_obegi[1] - islemci.yazmac_obegi[9])) begin
         $display("[ERR] SUB x12, x1, x9");
         $display("Expected: %0x, Actual: %0x", islemci.yazmac_obegi[1] - islemci.yazmac_obegi[9],
                  islemci.yazmac_obegi[12]);
      end else score = score + 1;
      buyruk_kontrol(1);  // 1 buyruk yurut
      if (islemci.yazmac_obegi[13] !== (islemci.yazmac_obegi[1] | islemci.yazmac_obegi[9])) begin
         $display("[ERR] OR x13, x1, x9");
         $display("Expected: %0x, Actual: %0x", islemci.yazmac_obegi[1] | islemci.yazmac_obegi[9],
                  islemci.yazmac_obegi[13]);
      end else score = score + 1;
      buyruk_kontrol(1);  // 1 buyruk yurut
      if (islemci.yazmac_obegi[14] !== (islemci.yazmac_obegi[1] & islemci.yazmac_obegi[9])) begin
         $display("[ERR] AND x14, x1, x9");
         $display("Expected: %0x, Actual: %0x", islemci.yazmac_obegi[1] & islemci.yazmac_obegi[9],
                  islemci.yazmac_obegi[14]);
      end else score = score + 1;
      buyruk_kontrol(1);  // 1 buyruk yurut
      if (islemci.yazmac_obegi[15] !== (islemci.yazmac_obegi[1] ^ islemci.yazmac_obegi[9])) begin
         $display("[ERR] XOR x15, x1, x9");
         $display("Expected: %0x, Actual: %0x", islemci.yazmac_obegi[1] ^ islemci.yazmac_obegi[9],
                  islemci.yazmac_obegi[15]);
      end else score = score + 1;

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
