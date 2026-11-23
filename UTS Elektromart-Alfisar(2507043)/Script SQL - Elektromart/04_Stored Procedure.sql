USE electromart;

DROP PROCEDURE IF EXISTS SP_Tampil_Produk;
DROP PROCEDURE IF EXISTS SP_Tambah_Produk;
DROP PROCEDURE IF EXISTS SP_Ubah_Harga;
DROP PROCEDURE IF EXISTS SP_Catat_Penjualan;
DROP PROCEDURE IF EXISTS SP_Tambah_Item_Penjualan;
DROP PROCEDURE IF EXISTS SP_Contoh_Hapus;

DELIMITER $$

CREATE PROCEDURE SP_Tampil_Produk()
BEGIN
    SELECT id_produk, nama_produk, kategori, harga, stok
    FROM produk
    ORDER BY id_produk;
END$$

CREATE PROCEDURE SP_Tambah_Produk(
    IN p_id_produk   VARCHAR(10),
    IN p_nama_produk VARCHAR(100),
    IN p_kategori    VARCHAR(50),
    IN p_harga       DECIMAL(12,2),
    IN p_stok        INT
)
BEGIN
    DECLARE v_ada INT DEFAULT 0;
    IF p_harga IS NULL OR p_harga <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Harga produk harus lebih dari 0';
    END IF;
    IF p_stok IS NULL OR p_stok < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stok tidak boleh negatif';
    END IF;
    SELECT COUNT(*) INTO v_ada FROM produk WHERE id_produk = p_id_produk;
    IF v_ada > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ID produk sudah terdaftar';
    END IF;
    INSERT INTO produk (id_produk, nama_produk, kategori, harga, stok)
    VALUES (p_id_produk, p_nama_produk, p_kategori, p_harga, p_stok);

    IF p_stok > 0 THEN
        INSERT INTO log_stok (id_produk, jumlah_perubahan, tipe_transaksi, keterangan)
        VALUES (p_id_produk, p_stok, 'MASUK', 'Stok awal produk baru (SP_Tambah_Produk)');
    END IF;
    SELECT * FROM produk WHERE id_produk = p_id_produk;
END$$

CREATE PROCEDURE SP_Ubah_Harga(
    IN p_id_produk  VARCHAR(10),
    IN p_harga_baru DECIMAL(12,2)
)
BEGIN
    DECLARE v_ada INT DEFAULT 0;
    DECLARE v_harga_lama DECIMAL(12,2);
    SELECT COUNT(*) INTO v_ada FROM produk WHERE id_produk = p_id_produk;
    IF v_ada = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ID produk tidak ditemukan';
    END IF;
    IF p_harga_baru IS NULL OR p_harga_baru <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Harga baru harus lebih dari 0';
    END IF;
    SELECT harga INTO v_harga_lama FROM produk WHERE id_produk = p_id_produk;
    UPDATE produk SET harga = p_harga_baru WHERE id_produk = p_id_produk;
    SELECT id_produk, nama_produk, v_harga_lama AS harga_lama, harga AS harga_baru
    FROM produk WHERE id_produk = p_id_produk;
END$$

CREATE PROCEDURE SP_Catat_Penjualan(
    IN p_id_penjualan VARCHAR(10),
    IN p_id_pelanggan VARCHAR(10),
    IN p_id_pegawai   VARCHAR(10)
)
BEGIN
    DECLARE v_peran VARCHAR(30);
    DECLARE v_pelanggan INT DEFAULT 0;
    SELECT peran INTO v_peran FROM pegawai WHERE id_pegawai = p_id_pegawai;
    IF v_peran IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pegawai tidak terdaftar';
    END IF;
    IF v_peran NOT IN ('role_penjualan','role_admin') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pegawai tidak berwenang melakukan penjualan';
    END IF;
    SELECT COUNT(*) INTO v_pelanggan FROM pelanggan WHERE id_pelanggan = p_id_pelanggan;
    IF v_pelanggan = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pelanggan tidak terdaftar';
    END IF;
    INSERT INTO penjualan (id_penjualan, tanggal, id_pelanggan, id_pegawai, total_harga, diskon, total_bayar)
    VALUES (p_id_penjualan, NOW(), p_id_pelanggan, p_id_pegawai, 0, 0, 0);
END$$

CREATE PROCEDURE SP_Tambah_Item_Penjualan(
    IN p_id_penjualan VARCHAR(10),
    IN p_id_produk    VARCHAR(10),
    IN p_jumlah       INT
)
BEGIN
    DECLARE v_harga DECIMAL(12,2);
    SELECT harga INTO v_harga FROM produk WHERE id_produk = p_id_produk;
    SET v_harga = IFNULL(v_harga, 0);
    INSERT INTO detail_penjualan (id_penjualan, id_produk, jumlah, harga_satuan, subtotal)
    VALUES (p_id_penjualan, p_id_produk, p_jumlah, v_harga, hitung_total(v_harga, p_jumlah));
END$$

CREATE PROCEDURE SP_Contoh_Hapus()
BEGIN
    SELECT 'Procedure ini hanya untuk contoh DROP PROCEDURE' AS pesan;
END$$

DELIMITER ;

SELECT routine_name AS nama_procedure, routine_type AS tipe, created AS dibuat
FROM information_schema.routines
WHERE routine_schema = 'electromart' AND routine_type = 'PROCEDURE'
ORDER BY routine_name;

CALL SP_Tampil_Produk();

CALL SP_Tambah_Produk('PRD011', 'Speaker Bluetooth JBL Flip 6', 'Audio', 1500000.00, 20);
CALL SP_Tambah_Produk('PRD012', 'Powerbank Anker 20000mAh', 'Aksesoris', 450000.00, 30);
CALL SP_Tampil_Produk();                              
SELECT * FROM log_stok WHERE id_produk IN ('PRD011','PRD012');  

CALL SP_Ubah_Harga('PRD011', 1650000.00);
CALL SP_Ubah_Harga('PRD012', 475000.00);
SELECT id_produk, nama_produk, harga FROM produk WHERE id_produk IN ('PRD011','PRD012');

CALL SP_Contoh_Hapus();
DROP PROCEDURE SP_Contoh_Hapus;
SELECT routine_name AS procedure_tersisa FROM information_schema.routines
WHERE routine_schema = 'electromart' AND routine_type = 'PROCEDURE' ORDER BY routine_name;   -- SP_Contoh_Hapus sudah hilang

GRANT EXECUTE ON PROCEDURE electromart.SP_Tampil_Produk         TO role_penjualan, role_gudang, role_manajer;
GRANT EXECUTE ON PROCEDURE electromart.SP_Catat_Penjualan       TO role_penjualan;
GRANT EXECUTE ON PROCEDURE electromart.SP_Tambah_Item_Penjualan TO role_penjualan;