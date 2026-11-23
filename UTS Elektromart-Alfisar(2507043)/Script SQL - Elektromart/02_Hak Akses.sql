USE electromart;

DROP USER IF EXISTS 'andi_admin'@'%', 'maya_sales'@'%', 'eko_gudang'@'%', 'hendra_manajer'@'%';
DROP ROLE IF EXISTS role_admin, role_penjualan, role_gudang, role_manajer;

CREATE ROLE role_admin;
CREATE ROLE role_penjualan;
CREATE ROLE role_gudang;
CREATE ROLE role_manajer;

GRANT ALL PRIVILEGES ON electromart.* TO role_admin;

GRANT SELECT ON electromart.produk    TO role_penjualan;
GRANT SELECT ON electromart.pelanggan TO role_penjualan;
GRANT SELECT, INSERT, UPDATE, DELETE ON electromart.penjualan        TO role_penjualan; 
GRANT SELECT, INSERT, UPDATE, DELETE ON electromart.detail_penjualan TO role_penjualan;  

GRANT SELECT ON electromart.produk TO role_gudang;
GRANT UPDATE (stok) ON electromart.produk TO role_gudang;       
GRANT SELECT, INSERT ON electromart.log_stok TO role_gudang;        

GRANT SELECT ON electromart.produk           TO role_manajer;
GRANT SELECT ON electromart.penjualan        TO role_manajer;
GRANT SELECT ON electromart.detail_penjualan TO role_manajer;

REVOKE UPDATE, DELETE ON electromart.penjualan        FROM role_penjualan;
REVOKE UPDATE, DELETE ON electromart.detail_penjualan FROM role_penjualan;

CREATE USER 'andi_admin'@'%'     IDENTIFIED BY 'Admin#123';  
CREATE USER 'maya_sales'@'%'     IDENTIFIED BY 'Sales#123';     
CREATE USER 'eko_gudang'@'%'     IDENTIFIED BY 'Gudang#123';   
CREATE USER 'hendra_manajer'@'%' IDENTIFIED BY 'Manajer#123';   

GRANT role_admin     TO 'andi_admin'@'%';
GRANT role_penjualan TO 'maya_sales'@'%';
GRANT role_gudang    TO 'eko_gudang'@'%';
GRANT role_manajer   TO 'hendra_manajer'@'%';

SET DEFAULT ROLE role_admin     TO 'andi_admin'@'%';
SET DEFAULT ROLE role_penjualan TO 'maya_sales'@'%';
SET DEFAULT ROLE role_gudang    TO 'eko_gudang'@'%';
SET DEFAULT ROLE role_manajer   TO 'hendra_manajer'@'%';

FLUSH PRIVILEGES;

SHOW GRANTS FOR role_admin;
SHOW GRANTS FOR role_penjualan;
SHOW GRANTS FOR role_gudang;
SHOW GRANTS FOR role_manajer;

SHOW GRANTS FOR 'maya_sales'@'%'     USING role_penjualan;
SHOW GRANTS FOR 'eko_gudang'@'%'     USING role_gudang;
SHOW GRANTS FOR 'hendra_manajer'@'%' USING role_manajer;

SELECT from_user AS role, to_user AS pengguna FROM mysql.role_edges
WHERE to_user IN ('andi_admin','maya_sales','eko_gudang','hendra_manajer') ORDER BY to_user;

SELECT id_pegawai, nama_pegawai, peran,
       CASE peran WHEN 'role_admin' THEN 'andi_admin'
                  WHEN 'role_penjualan' THEN 'maya_sales'
                  WHEN 'role_gudang' THEN 'eko_gudang'
                  WHEN 'role_manajer' THEN 'hendra_manajer' END AS akun_mysql
FROM electromart.pegawai;