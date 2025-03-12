`timescale 1ns / 1ps

module tb_kirbysort ();

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
   integer elem_count;
   integer start_idx;
   integer ks_index;
   integer write_reg;
   integer err_count;
   integer alt_err_count;
   integer result;
   reg [VERI_BIT-1:0] conf[0:7];
   reg [VERI_BIT-1:0] ks[0:15];
   reg [VERI_BIT-1:0] temp;
   initial begin
      stall_ctr = 0;
      rst_r = 1'b1;

      result = 0;
      @(posedge clk_r);

      bellek_yaz('h8000_0000, {7'd0, 5'd5, 5'd2, 3'd1, 5'd15, 7'b1110011}); // ks  x15, x2, 5
      bellek_yaz('h8000_0004, {7'd0, 5'd5, 5'd2, 3'd1, 5'd15, 7'b1110011}); // ks  x15, x2, 5
      bellek_yaz('h8000_0008, {7'd0, 5'd10, 5'd2, 3'd1, 5'd15, 7'b1110011}); // ks  x15, x2, 10

      repeat (10) @(posedge clk_r);
      #2;  // 10 cevrim reset
      rst_r = 1'b0;

      // Initialize registers
      elem_count = 5;
      start_idx = 2;
      for (reg_num = 0; reg_num < elem_count; reg_num = reg_num + 1) begin
         islemci_ous.yazmac_obegi[reg_num + start_idx] = reg_num + 1;
      end

      // Execute kirbysort and fill KS verification registers
      alt_err_count = 0;
      kirbysort(start_idx, elem_count);
      buyruk_kontrol(1);  // 1 buyruk yurut
      write_reg = 15;
      for (reg_num = 0; reg_num < elem_count; reg_num = reg_num + 1) begin
         if (yazmac_oku(reg_num + write_reg) !== ks[reg_num]) begin
            $display("[ERR] TEST-1: ks yazmac %0d expected %0d, actual %0d", (reg_num + write_reg),
                     ks[reg_num], yazmac_oku(reg_num + write_reg));
         end else result = result + 1;
         if (yazmac_oku(reg_num + start_idx) !== ks[reg_num]) begin
            alt_err_count = alt_err_count + 1;
         end
      end

      if (alt_err_count === 0 && result < 5) result = result + 2;

      elem_count = 5;
      start_idx = 2;
      for (reg_num = 0; reg_num < elem_count; reg_num = reg_num + 1) begin
         islemci_ous.yazmac_obegi[reg_num + start_idx] = 5 - reg_num;
      end

      err_count = 0;
      alt_err_count = 0;
      kirbysort(start_idx, elem_count);
      buyruk_kontrol(1);  // 1 buyruk yurut
      write_reg = 15;
      for (reg_num = 0; reg_num < ks_index; reg_num = reg_num + 1) begin
         if (yazmac_oku(reg_num + write_reg) !== ks[reg_num]) begin
            $display("[ERR] TEST-2: ks yazmac %0d expected %0d, actual %0d", (reg_num + write_reg),
                     ks[reg_num], yazmac_oku(reg_num + write_reg));
            err_count = err_count + 1;
         end
         if (yazmac_oku(reg_num + start_idx) !== ks[reg_num]) begin
            alt_err_count = alt_err_count + 1;
         end
      end

      if (err_count === 0) result = result + 5;
      else if (err_count === ks_index && alt_err_count === 0) result = result + 2;

      islemci_ous.yazmac_obegi[2] = 5;
      islemci_ous.yazmac_obegi[3] = 2;
      islemci_ous.yazmac_obegi[4] = 1;
      islemci_ous.yazmac_obegi[5] = 15;
      islemci_ous.yazmac_obegi[6] = 18;
      islemci_ous.yazmac_obegi[7] = 3;
      islemci_ous.yazmac_obegi[8] = 7;
      islemci_ous.yazmac_obegi[9] = 9;
      islemci_ous.yazmac_obegi[10] = 40;
      islemci_ous.yazmac_obegi[11] = 20;
      elem_count = 10;

      err_count = 0;
      kirbysort(start_idx, elem_count);
      buyruk_kontrol(1);  // 1 buyruk yurut
      write_reg = 15;
      for (reg_num = 0; reg_num < ks_index; reg_num = reg_num + 1) begin
         if (yazmac_oku(reg_num + write_reg) !== ks[reg_num]) begin
            $display("[ERR] TEST-3: ks yazmac %0d expected %0d, actual %0d", (reg_num + write_reg),
                     ks[reg_num], yazmac_oku(reg_num + write_reg));
            err_count = err_count + 1;
         end
      end

      if (err_count === 0) result = result + 20;
      else if (err_count < 2) result = result + 10;
      else if (err_count < 4) result = result + 5;
      else if (alt_err_count === 0 && err_count === ks_index) result = result + 12;

      $display("[INFO] Result:%0d", result);
      $finish;
   end

   integer max;
   task kirbysort (input integer start_index, input integer length);
   begin
      max = 0;
      ks_index = 0;
      for (reg_num = 0; reg_num < 16; reg_num = reg_num + 1) begin
         ks[reg_num] = 0;
      end
      for (reg_num = 0; reg_num < length; reg_num = reg_num + 1) begin
         if (yazmac_oku(reg_num + start_index) > max) begin
            max = yazmac_oku(reg_num + start_index);
            ks[ks_index] = yazmac_oku(reg_num + start_index);
            ks_index = ks_index + 1;
         end
      end
   end
   endtask

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
