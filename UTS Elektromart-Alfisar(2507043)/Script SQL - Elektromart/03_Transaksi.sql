USE electromart;

SELECT id_produk, nama_produk, stok FROM produk WHERE id_produk IN ('PRD001','PRD002','PRD006','PRD008','PRD010');

START TRANSACTION;

INSERT INTO penjualan (id_penjualan, tanggal, id_pelanggan, id_pegawai, total_harga, diskon, total_bayar)
VALUES ('TRX005', NOW(), 'PLG005', 'PGW002', 15000000.00, 1500000.00, 13500000.00);

INSERT INTO detail_penjualan (id_penjualan, id_produk, jumlah, harga_satuan, subtotal)
VALUES ('TRX005', 'PRD001', 1, 14500000.00, 14500000.00),
       ('TRX005', 'PRD002', 2,   250000.00,   500000.00);

UPDATE produk SET stok = stok - 1 WHERE id_produk = 'PRD001';
UPDATE produk SET stok = stok - 2 WHERE id_produk = 'PRD002';

INSERT INTO log_stok (id_produk, jumlah_perubahan, tipe_transaksi, keterangan)
VALUES ('PRD001', -1, 'KELUAR', 'Pengurangan stok dari TRX005'),
       ('PRD002', -2, 'KELUAR', 'Pengurangan stok dari TRX005');

COMMIT;

SELECT * FROM penjualan WHERE id_penjualan = 'TRX005';
SELECT * FROM detail_penjualan WHERE id_penjualan = 'TRX005';
SELECT id_produk, nama_produk, stok FROM produk WHERE id_produk IN ('PRD001','PRD002');   -- 14 dan 48
SELECT * FROM log_stok WHERE keterangan LIKE '%TRX005%';

SELECT id_produk, nama_produk, stok AS stok_sebelum FROM produk WHERE id_produk = 'PRD006';   -- 2

START TRANSACTION;

INSERT INTO penjualan (id_penjualan, tanggal, id_pelanggan, id_pegawai, total_harga, diskon, total_bayar)
VALUES ('TRX900', NOW(), 'PLG003', 'PGW002', 42500000.00, 4250000.00, 38250000.00);

INSERT INTO detail_penjualan (id_penjualan, id_produk, jumlah, harga_satuan, subtotal)
VALUES ('TRX900', 'PRD006', 5, 8500000.00, 42500000.00);

UPDATE produk SET stok = stok - 5 WHERE id_produk = 'PRD006';

SELECT id_produk, stok AS stok_di_dalam_transaksi,
       IF(stok < 0, 'STOK TIDAK CUKUP -> HARUS ROLLBACK', 'OK') AS status
FROM produk WHERE id_produk = 'PRD006';
SELECT * FROM penjualan WHERE id_penjualan = 'TRX900';     

ROLLBACK;  

SELECT id_produk, stok AS stok_sesudah_rollback FROM produk WHERE id_produk = 'PRD006';      
SELECT COUNT(*) AS jumlah_trx900 FROM penjualan WHERE id_penjualan = 'TRX900';               
SELECT COUNT(*) AS jumlah_detail_trx900 FROM detail_penjualan WHERE id_penjualan = 'TRX900';  

START TRANSACTION;

INSERT INTO penjualan (id_penjualan, tanggal, id_pelanggan, id_pegawai, total_harga, diskon, total_bayar)
VALUES ('TRX006', NOW(), 'PLG002', 'PGW002', 425000.00, 0.00, 425000.00);
SAVEPOINT sp_header;                                    

INSERT INTO detail_penjualan (id_penjualan, id_produk, jumlah, harga_satuan, subtotal)
VALUES ('TRX006', 'PRD008', 5, 85000.00, 425000.00);
UPDATE produk SET stok = stok - 5 WHERE id_produk = 'PRD008';
INSERT INTO log_stok (id_produk, jumlah_perubahan, tipe_transaksi, keterangan)
VALUES ('PRD008', -5, 'KELUAR', 'Pengurangan stok dari TRX006');
SAVEPOINT sp_flashdisk;                             

INSERT INTO detail_penjualan (id_penjualan, id_produk, jumlah, harga_satuan, subtotal)
VALUES ('TRX006', 'PRD010', 1, 950000.00, 950000.00);
UPDATE produk SET stok = stok - 1 WHERE id_produk = 'PRD010';
INSERT INTO log_stok (id_produk, jumlah_perubahan, tipe_transaksi, keterangan)
VALUES ('PRD010', -1, 'KELUAR', 'Pengurangan stok dari TRX006');
UPDATE penjualan SET total_harga = 1375000.00, diskon = 137500.00, total_bayar = 1237500.00
WHERE id_penjualan = 'TRX006';

SELECT 'sebelum rollback to savepoint' AS tahap, id_produk, jumlah FROM detail_penjualan WHERE id_penjualan = 'TRX006';
SELECT 'sebelum rollback to savepoint' AS tahap, total_harga, diskon, total_bayar FROM penjualan WHERE id_penjualan = 'TRX006';

ROLLBACK TO SAVEPOINT sp_flashdisk;

SELECT 'sesudah rollback to savepoint' AS tahap, id_produk, jumlah FROM detail_penjualan WHERE id_penjualan = 'TRX006';
SELECT 'sesudah rollback to savepoint' AS tahap, total_harga, diskon, total_bayar FROM penjualan WHERE id_penjualan = 'TRX006';

RELEASE SAVEPOINT sp_flashdisk;
RELEASE SAVEPOINT sp_header;
COMMIT;

SELECT * FROM penjualan WHERE id_penjualan = 'TRX006';                    
SELECT * FROM detail_penjualan WHERE id_penjualan = 'TRX006';                
SELECT id_produk, nama_produk, stok FROM produk WHERE id_produk IN ('PRD008','PRD010');  
SELECT * FROM log_stok WHERE keterangan LIKE '%TRX006%';                      

SELECT * FROM penjualan ORDER BY id_penjualan;
SELECT id_produk, nama_produk, stok FROM produk ORDER BY id_produk;