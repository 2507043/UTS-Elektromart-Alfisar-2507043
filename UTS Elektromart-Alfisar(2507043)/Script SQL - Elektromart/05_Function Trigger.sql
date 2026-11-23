USE electromart;

DROP TRIGGER IF EXISTS validasi_penjualan;
DROP TRIGGER IF EXISTS update_stok_penjualan;
DROP TRIGGER IF EXISTS hitung_total_penjualan;
DROP FUNCTION IF EXISTS hitung_total;
DROP FUNCTION IF EXISTS hitung_diskon;
DROP PROCEDURE IF EXISTS sp_uji_tambah_item;

DELIMITER $$

CREATE FUNCTION hitung_total(p_harga DECIMAL(12,2), p_jumlah INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    RETURN p_harga * p_jumlah;
END$$

CREATE FUNCTION hitung_diskon(p_total DECIMAL(12,2))
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    IF p_total >= 1000000 THEN
        RETURN p_total * 0.10;
    END IF;
    RETURN 0;
END$$

CREATE TRIGGER validasi_penjualan
BEFORE INSERT ON detail_penjualan
FOR EACH ROW
BEGIN
    DECLARE v_ada INT DEFAULT 0;
    DECLARE v_stok INT DEFAULT 0;
    SELECT COUNT(*) INTO v_ada FROM produk WHERE id_produk = NEW.id_produk;
    IF v_ada = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Produk tidak terdaftar';
    END IF;
    IF NEW.jumlah IS NULL OR NEW.jumlah <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jumlah pembelian harus lebih dari 0';
    END IF;
    IF NEW.harga_satuan IS NULL OR NEW.harga_satuan <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Harga satuan harus lebih dari 0';
    END IF;
    SELECT stok INTO v_stok FROM produk WHERE id_produk = NEW.id_produk FOR UPDATE;
    IF v_stok < NEW.jumlah THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stok tidak mencukupi untuk pembelian ini';
    END IF;
    SET NEW.subtotal = hitung_total(NEW.harga_satuan, NEW.jumlah);
END$$

CREATE TRIGGER update_stok_penjualan
AFTER INSERT ON detail_penjualan
FOR EACH ROW
BEGIN
    UPDATE produk SET stok = stok - NEW.jumlah WHERE id_produk = NEW.id_produk;
    INSERT INTO log_stok (id_produk, jumlah_perubahan, tipe_transaksi, keterangan)
    VALUES (NEW.id_produk, -NEW.jumlah, 'KELUAR', CONCAT('Pengurangan stok dari ', NEW.id_penjualan));
END$$

CREATE TRIGGER hitung_total_penjualan
AFTER INSERT ON detail_penjualan
FOR EACH ROW
BEGIN
    UPDATE penjualan
    SET total_harga = total_harga + NEW.subtotal,
        diskon      = hitung_diskon(total_harga),
        total_bayar = total_harga - diskon
    WHERE id_penjualan = NEW.id_penjualan;
END$$

CREATE PROCEDURE sp_uji_tambah_item(
    IN p_id_penjualan VARCHAR(10),
    IN p_id_produk    VARCHAR(10),
    IN p_jumlah       INT,
    IN p_harga        DECIMAL(12,2)
)
BEGIN
    DECLARE v_pesan TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_pesan = MESSAGE_TEXT;
        SELECT 'DITOLAK' AS hasil, p_id_penjualan AS id_penjualan, p_id_produk AS id_produk,
               p_jumlah AS jumlah, p_harga AS harga, v_pesan AS alasan;
    END;
    INSERT INTO detail_penjualan (id_penjualan, id_produk, jumlah, harga_satuan, subtotal)
    VALUES (p_id_penjualan, p_id_produk, p_jumlah, p_harga, 0);
    SELECT 'BERHASIL' AS hasil, p_id_penjualan AS id_penjualan, p_id_produk AS id_produk,
           p_jumlah AS jumlah, p_harga AS harga, 'Data valid dan tersimpan' AS alasan;
END$$

DELIMITER ;

SELECT routine_name AS nama, routine_type AS tipe FROM information_schema.routines
WHERE routine_schema = 'electromart' AND routine_type = 'FUNCTION';
SELECT trigger_name AS nama_trigger, action_timing AS waktu, event_manipulation AS event, event_object_table AS tabel
FROM information_schema.triggers WHERE trigger_schema = 'electromart' ORDER BY action_order;

SELECT hitung_total(14500000, 1)  AS total_1_laptop,
       hitung_total(250000, 2)    AS total_2_mouse,
       hitung_diskon(999999)      AS diskon_999rb,      
       hitung_diskon(1000000)     AS diskon_tepat_1jt, 
       hitung_diskon(15000000)    AS diskon_15jt;        

SELECT id_penjualan,
       SUM(subtotal)                         AS total_dari_detail,
       hitung_diskon(SUM(subtotal))          AS diskon_dari_function,
       SUM(subtotal) - hitung_diskon(SUM(subtotal)) AS bayar_dari_function,
       (SELECT diskon FROM penjualan p WHERE p.id_penjualan = d.id_penjualan) AS diskon_di_tabel
FROM detail_penjualan d
WHERE id_penjualan IN ('TRX001','TRX002','TRX003','TRX004')
GROUP BY id_penjualan;

INSERT INTO penjualan (id_penjualan, id_pelanggan, id_pegawai) VALUES ('TRX101','PLG001','PGW002');
INSERT INTO penjualan (id_penjualan, id_pelanggan, id_pegawai) VALUES ('TRX102','PLG002','PGW002');
INSERT INTO penjualan (id_penjualan, id_pelanggan, id_pegawai) VALUES ('TRX103','PLG003','PGW002');
INSERT INTO penjualan (id_penjualan, id_pelanggan, id_pegawai) VALUES ('TRX104','PLG004','PGW002');

SELECT id_produk, nama_produk, stok AS stok_sebelum FROM produk
WHERE id_produk IN ('PRD002','PRD004','PRD006','PRD008') ORDER BY id_produk;

CALL sp_uji_tambah_item('TRX101', 'PRD002', 2, 250000.00);

CALL sp_uji_tambah_item('TRX102', 'PRD004', 1, 3200000.00);
CALL sp_uji_tambah_item('TRX102', 'PRD008', 2, 85000.00);

CALL sp_uji_tambah_item('TRX103', 'PRD002', 4, 250000.00);

CALL sp_uji_tambah_item('TRX104', 'PRD006', 5, 8500000.00);

CALL sp_uji_tambah_item('TRX104', 'PRD002', 0, 250000.00);
CALL sp_uji_tambah_item('TRX104', 'PRD002', -3, 250000.00);

CALL sp_uji_tambah_item('TRX104', 'PRD999', 1, 100000.00);

CALL sp_uji_tambah_item('TRX104', 'PRD002', 1, 0);

SELECT id_penjualan, total_harga, diskon, total_bayar,
       CASE WHEN total_harga = 0 THEN 'kosong (semua item ditolak)'
            WHEN diskon > 0 THEN 'DAPAT diskon 10%' ELSE 'tanpa diskon' END AS keterangan
FROM penjualan WHERE id_penjualan IN ('TRX101','TRX102','TRX103','TRX104') ORDER BY id_penjualan;

SELECT id_detail, id_penjualan, id_produk, jumlah, harga_satuan, subtotal
FROM detail_penjualan WHERE id_penjualan IN ('TRX101','TRX102','TRX103','TRX104') ORDER BY id_detail;

SELECT id_produk, nama_produk, stok AS stok_sesudah FROM produk
WHERE id_produk IN ('PRD002','PRD004','PRD006','PRD008') ORDER BY id_produk;

SELECT id_log, id_produk, jumlah_perubahan, tipe_transaksi, keterangan, tanggal
FROM log_stok WHERE keterangan REGEXP 'TRX10[1-4]' ORDER BY id_log;

DELETE FROM penjualan WHERE id_penjualan = 'TRX104';