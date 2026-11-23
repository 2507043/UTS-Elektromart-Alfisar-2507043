USE electromart;

DROP VIEW IF EXISTS View_Produk;
DROP VIEW IF EXISTS View_Transaksi;
DROP VIEW IF EXISTS View_Laporan_Penjualan;
DROP VIEW IF EXISTS View_Laporan_Bulanan;
DROP VIEW IF EXISTS View_Stok_Rendah;
DROP VIEW IF EXISTS View_Produk_Aksesoris;

CREATE VIEW View_Produk AS
SELECT id_produk, nama_produk, kategori, harga,
       CASE WHEN stok = 0 THEN 'Habis'
            WHEN stok < 5 THEN 'Terbatas'
            ELSE 'Tersedia' END AS status_stok
FROM produk;
CREATE VIEW View_Transaksi AS
SELECT p.id_penjualan, p.tanggal,
       pl.nama_pelanggan,
       pg.nama_pegawai AS kasir,
       p.total_harga, p.diskon, p.total_bayar
FROM penjualan p
JOIN pelanggan pl ON pl.id_pelanggan = p.id_pelanggan
JOIN pegawai   pg ON pg.id_pegawai   = p.id_pegawai;

CREATE VIEW View_Laporan_Penjualan AS
SELECT DATE_FORMAT(p.tanggal, '%Y-%m') AS periode,
       pr.kategori,
       COUNT(DISTINCT p.id_penjualan) AS jumlah_transaksi,
       SUM(d.jumlah)                  AS unit_terjual,
       SUM(d.subtotal)                AS total_penjualan
FROM penjualan p
JOIN detail_penjualan d ON d.id_penjualan = p.id_penjualan
JOIN produk pr          ON pr.id_produk   = d.id_produk
GROUP BY DATE_FORMAT(p.tanggal, '%Y-%m'), pr.kategori;

CREATE VIEW View_Laporan_Bulanan AS
SELECT DATE_FORMAT(tanggal, '%Y-%m') AS periode,
       COUNT(*)         AS jumlah_transaksi,
       SUM(total_harga) AS total_kotor,
       SUM(diskon)      AS total_diskon,
       SUM(total_bayar) AS total_penjualan
FROM penjualan
GROUP BY DATE_FORMAT(tanggal, '%Y-%m');

CREATE VIEW View_Stok_Rendah AS
SELECT id_produk, nama_produk, kategori, harga, stok
FROM produk
WHERE stok < 5
WITH CHECK OPTION;

SELECT table_name AS nama_view, is_updatable AS bisa_diupdate

SELECT * FROM View_Produk;                                
SELECT * FROM View_Produk WHERE kategori = 'Aksesoris';     
SELECT * FROM View_Transaksi ORDER BY tanggal;          
SELECT * FROM View_Laporan_Penjualan ORDER BY periode, kategori;  
SELECT * FROM View_Laporan_Bulanan;
SELECT * FROM View_Stok_Rendah;

SELECT SUM(total_penjualan) AS total_dari_view,
       (SELECT SUM(subtotal) FROM detail_penjualan) AS total_dari_tabel
FROM View_Laporan_Penjualan;
UPDATE View_Stok_Rendah SET stok = 3 WHERE id_produk = 'PRD009';

SELECT * FROM View_Stok_Rendah;                           
UPDATE produk SET stok = 4 WHERE id_produk = 'PRD009';

CREATE VIEW View_Produk_Aksesoris AS
SELECT id_produk, nama_produk, harga FROM produk WHERE kategori = 'Aksesoris';
SELECT * FROM View_Produk_Aksesoris;
DROP VIEW View_Produk_Aksesoris;
SELECT table_name AS view_tersisa FROM information_schema.views
WHERE table_schema = 'electromart' ORDER BY table_name;     

REVOKE SELECT ON electromart.produk           FROM role_manajer;
REVOKE SELECT ON electromart.penjualan        FROM role_manajer;
REVOKE SELECT ON electromart.detail_penjualan FROM role_manajer;
GRANT SELECT ON electromart.View_Produk             TO role_manajer;
GRANT SELECT ON electromart.View_Transaksi          TO role_manajer;
GRANT SELECT ON electromart.View_Laporan_Penjualan  TO role_manajer;
GRANT SELECT ON electromart.View_Laporan_Bulanan    TO role_manajer;
GRANT SELECT ON electromart.View_Stok_Rendah        TO role_manajer;

GRANT SELECT ON electromart.View_Produk       TO role_penjualan;
GRANT SELECT ON electromart.View_Stok_Rendah  TO role_gudang;

SHOW GRANTS FOR role_manajer;