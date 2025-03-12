`timescale 1ns / 1ps

module tb_dogestore ();

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

   islemci_ous islemci_ous (
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
   integer reg_num;
   integer start_reg;
   integer start_idx;
   integer err_count;
   integer result;
   reg [VERI_BIT-1:0] temp;
   initial begin
      stall_ctr = 0;
      rst_r = 1'b1;

      result = 0;
      err_count = 0;
      @(posedge clk_r);

      bellek_yaz('h8000_0000, {7'd0, 5'd30, 5'd1, 3'd2, 5'd13, 7'b1110011});  // ds   x13, x1, 31

      repeat (10) @(posedge clk_r);
      #2;  // 10 cevrim reset
      rst_r = 1'b0;

      for (reg_num = 1; reg_num < 32; reg_num = reg_num + 1) begin
         islemci_ous.yazmac_obegi[reg_num] = $urandom % 32'hffff_ffff;
      end

      islemci_ous.yazmac_obegi[13] = 32'h8000_1000;

      $display("[INFO] REG DUMP");
      for (reg_num = 0; reg_num < 32; reg_num = reg_num + 1) begin
         $display("[INFO] x%0d: %0h", reg_num, islemci_ous.yazmac_obegi[reg_num]);
      end

      buyruk_kontrol(1);  // 1 buyruk yurut
      start_reg = 1;
      for (reg_num = 0; reg_num < 30; reg_num = reg_num + 1) begin
         if (yazmac_oku(reg_num + start_reg) !== bellek_oku(32'h8000_1000 + (4 * reg_num))) begin
            $display("[ERR] DS: x%0d yazmacinin degeri: %0d, Bellek adresi: 0x%h, degeri: %0d",
                     (reg_num + start_reg), yazmac_oku(reg_num + start_reg),
                     32'h8000_1000 + (4 * reg_num), bellek_oku(32'h8000_1000 + (4 * reg_num)));
            err_count = err_count + 1;
         end else result = result + 1;
      end

      if (err_count < 8 && result !== 30) result = result + 3;
      else if (err_count < 15 && result !== 30) result = result + 2;
      else if (err_count < 30 && result !== 30) result = result + 1;

      $display("[INFO] Result:%0d", result);
      $finish;
   end

   // Islemcide buyruk_sayisi kadar buyruk yurutulmesini izler ve asama sirasini kontrol eder.
   task buyruk_kontrol(input [31:0] buyruk_sayisi);
      integer counter;
      begin
         for (counter = 0; counter < buyruk_sayisi; counter = counter + 1) begin
            while (!islemci_ous.ilerle_cmb) @(posedge clk_r) #2;
            asama_kontrol(islemci_ous.GETIR);
            @(posedge clk_r) #2;
            while (!islemci_ous.ilerle_cmb) @(posedge clk_r) #2;
            asama_kontrol(islemci_ous.COZYAZMACOKU);
            @(posedge clk_r) #2;
            while (!islemci_ous.ilerle_cmb) @(posedge clk_r) #2;
            asama_kontrol(islemci_ous.YURUTGERIYAZ);
            @(posedge clk_r) #2;
         end
      end
   endtask

   task asama_kontrol(input [1:0] beklenen);
      begin
         if (islemci_ous.simdiki_asama_r !== beklenen) begin
            $display("[ERR] YANLIS ASAMA expected: %0x actual: %0x", beklenen,
                     islemci_ous.simdiki_asama_r);
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
         yazmac_oku = islemci_ous.yazmac_obegi[yazmac_idx];
      end
   endfunction

   // Verilen adresi bellek satir indisine donusturur.
   function integer adres_satir_idx(input [ADRES_BIT-1:0] adres);
      begin
         adres_satir_idx = (adres - BELLEK_ADRES) >> $clog2(VERI_BIT / 8);
      end
   endfunction

endmodule
