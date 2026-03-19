CREATE DATABASE QuanlybanhangCanifa;
USE QuanlybanhangCanifa;
go
-- Tạo bảng NhanVien
CREATE TABLE NhanVien (
    MaNhanVien CHAR(10) PRIMARY KEY,
    HoTenNV NVARCHAR(50) NOT NULL,
    NgaySinhNV DATE NOT NULL,
    GioiTinhNV NVARCHAR(10) 
	CHECK (GioiTinhNV IN (N'Nam', N'Nữ', N'Khác')),
    EmailNV VARCHAR(50) NOT NULL UNIQUE,
    SDTNV CHAR(10),
    -- Ràng buộc kiểm tra tuổi ≥ 18
    CONSTRAINT CK_TuoiNhanVien CHECK (DATEDIFF(YEAR, NgaySinhNV, GETDATE()) >= 18)
);
GO  -- ← TÁCH BATCH trước khi tạo TRIGGER

-- Trigger kiểm tra tuổi kỹ hơn sau khi INSERT hoặc UPDATE
CREATE TRIGGER TR_CK_TuoiNhanVien
ON NhanVien
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE DATEDIFF(YEAR, NgaySinhNV, GETDATE()) < 18
    )
    BEGIN
        RAISERROR(N'Nhân viên phải đủ ít nhất 18 tuổi.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;


go
CREATE TABLE QuyenHan (
    MaQuyenHan CHAR(10) PRIMARY KEY,
    TenQuyenHan NVARCHAR(50) NOT NULL
);
go
CREATE TABLE TaiKhoan (
    MaTaiKhoan CHAR(10) PRIMARY KEY,
    TenTaiKhoan NVARCHAR(200) NOT NULL,
    TenDangNhap VARCHAR(200) UNIQUE NOT NULL,
    MatKhau VARCHAR(10) NOT NULL,
    TrangThaiHoatDong NVARCHAR(50) DEFAULT N'Đang hoạt động',
    MaQuyenHan CHAR(10),
    MaNhanVien CHAR(10),
    CONSTRAINT FK_TaiKhoan_QuyenHan FOREIGN KEY (MaQuyenHan) REFERENCES QuyenHan(MaQuyenHan),
    CONSTRAINT FK_TaiKhoan_NhanVien FOREIGN KEY (MaNhanVien) REFERENCES NhanVien(MaNhanVien)
);
go
CREATE TABLE DanhMucSanPham (
    MaDanhMucSanPham CHAR(10) PRIMARY KEY,
    TenDanhMuc nVARCHAR(200) NOT NULL
);
go
CREATE TABLE SanPham (
    IDSanPham CHAR(10) PRIMARY KEY,
    TenSanPham nVARCHAR(200) NOT NULL,
    MoTa nVARCHAR(200),
    MaDanhMucSanPham CHAR(10),
    FOREIGN KEY (MaDanhMucSanPham) REFERENCES DanhMucSanPham(MaDanhMucSanPham)
);
CREATE TABLE KhachHang (
    IDKhachHang CHAR(10) PRIMARY KEY,
    HoTen nVARCHAR(200) NOT NULL,
    EmailKH VARCHAR(20) UNIQUE,
    DiaChiKH nVARCHAR(200),
    SDT CHAR(10) NOT NULL
);
go
CREATE TABLE PhuongThucThanhToan (
    MaPhuongThucThanhToan CHAR(10) PRIMARY KEY,
    TenPhuongThucThanhToan nVARCHAR(200) NOT NULL
);
go
CREATE TABLE ChungTu (
    MaChungTu CHAR(10) PRIMARY KEY,
    TenChungTu nVARCHAR(50),
    NgayLap DATETIME NOT NULL
);
go
CREATE TABLE HoaDon (
    MaChungTu CHAR(10) PRIMARY KEY,
    TrangThaiThanhToan nVARCHAR(10),
    FOREIGN KEY (MaChungTu) REFERENCES ChungTu(MaChungTu)
);
CREATE TABLE PhieuHoanTra (
    MaChungTu CHAR(10) PRIMARY KEY,
    NgayTra DATETIME,
    LyDo nVARCHAR(200),
    TrangThai nVARCHAR(50),
    FOREIGN KEY (MaChungTu) REFERENCES ChungTu(MaChungTu)

);
SELECT name 
FROM sys.foreign_keys 
WHERE parent_object_id = OBJECT_ID('ChiTietHoanTra');
-- Xoá các khoá ngoại theo đúng tên (nếu biết rõ tên)
SELECT name 
FROM sys.foreign_keys 
WHERE parent_object_id = OBJECT_ID('PhieuHoanTra');


go
-- Bảng DONHANG
CREATE TABLE DonHang (
    MaDonHang CHAR(10) PRIMARY KEY,
    NgayDatHang DATETIME NOT NULL,
    TrangThaiDonHang NVARCHAR(50),
    IDKhachHang CHAR(10) NOT NULL,
    FOREIGN KEY (IDKhachHang) REFERENCES KhachHang(IDKhachHang)
);
go 
CREATE TRIGGER TR_Check_HoaDon_PhaiCoDonHang
ON HoaDon
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted h
        WHERE NOT EXISTS (
            SELECT 1
            FROM DonHang d
            WHERE d.MaDonHang = h.MaChungTu
        )
    )
    BEGIN
        RAISERROR(N'Hóa đơn phải gắn với đơn hàng hợp lệ.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;

go
-- Bảng PHIEUGIAOHANG (đã sửa lỗi dấu phẩy và thêm FK DonHang)
GO
-- Trigger kiểm tra: Ngày giao không nhỏ hơn ngày đặt
CREATE TRIGGER TR_Check_NgayGiao_Sau_NgayDat
ON PhieuGiaoHang
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted pg
        JOIN DonHang dh ON pg.MaDonHang = dh.MaDonHang
        WHERE pg.NgayGiao < dh.NgayDatHang
    )
    BEGIN
        RAISERROR(N'Ngày giao hàng không được trước ngày đặt hàng.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;
GO
CREATE TRIGGER TR_Check_NgayTra_Sau_NgayGiao
ON PhieuHoanTra
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted pt
        JOIN PhieuGiaoHang pg ON pt.MaChungTu = pg.MaChungTu
        WHERE pt.NgayTra < pg.NgayGiao
    )
    BEGIN
        RAISERROR(N'Ngày hoàn trả không được trước ngày giao hàng.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;

go
CREATE TABLE ChiTietDonHang (
    MaDonHang CHAR(10),
    IDSanPham CHAR(10),
    SoLuong INT NOT NULL,
    DonGia DECIMAL(12, 2) NOT NULL,
    CONSTRAINT PK_ChiTietDonHang PRIMARY KEY (MaDonHang, IDSanPham),
    CONSTRAINT FK_ChiTietDonHang_DonHang FOREIGN KEY (MaDonHang) REFERENCES DonHang(MaDonHang),
    CONSTRAINT FK_ChiTietDonHang_SanPham FOREIGN KEY (IDSanPham) REFERENCES SanPham(IDSanPham),
    CONSTRAINT CK_TongTienChiTiet CHECK (SoLuong * DonGia >= 0)
);
go
CREATE TRIGGER TR_Check_DonHang_PhaiCoChiTiet
ON DonHang
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted d
        WHERE NOT EXISTS (
            SELECT 1
            FROM ChiTietDonHang c
            WHERE c.MaDonHang = d.MaDonHang
        )
    )
    BEGIN
        RAISERROR(N'Đơn hàng phải có ít nhất một dòng chi tiết.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;
go 
CREATE TRIGGER TR_Prevent_Delete_All_ChiTiet
ON ChiTietDonHang
AFTER DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM DonHang d
        WHERE NOT EXISTS (
            SELECT 1 FROM ChiTietDonHang c
            WHERE c.MaDonHang = d.MaDonHang
        )
    )
    BEGIN
        RAISERROR(N'Không thể xóa hết chi tiết của đơn hàng.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;

go
CREATE TABLE ChiTietHoaDon (
    MaHoaDon CHAR(10),
    IDSanPham CHAR(10),
    SoLuong INT NOT NULL,
    DonGia DECIMAL(12,2) NOT NULL,
    ThanhTien AS (SoLuong * DonGia) PERSISTED, -- nếu hệ quản trị hỗ trợ
    PRIMARY KEY (MaHoaDon, IDSanPham),
    FOREIGN KEY (MaHoaDon) REFERENCES HoaDon(MaChungTu),
    FOREIGN KEY (IDSanPham) REFERENCES SanPham(IDSanPham)
);
go
CREATE TABLE PhieuGiaoHang (
    MaGiaoHang CHAR(10) PRIMARY KEY,           -- Mã phiếu giao hàng, định dạng 10 ký tự
    NgayGiao DATETIME NOT NULL,                -- Ngày giao hàng
    MaDonHang CHAR(10) NOT NULL,               -- Mã đơn hàng, liên kết với bảng DonHang
    TrangThaiGiao NVARCHAR(50) DEFAULT N'Chưa giao', -- Trạng thái giao hàng
    FOREIGN KEY (MaDonHang) REFERENCES DonHang(MaDonHang)  -- Khóa ngoại liên kết với bảng DonHang
);
CREATE TABLE ChiTietPhieuGiaoHang (
    MaGiaoHang CHAR(10),                       -- Mã phiếu giao hàng, tham chiếu từ bảng PhieuGiaoHang
    IDSanPham CHAR(10),                        -- Mã sản phẩm, tham chiếu từ bảng SanPham
    SoLuongGiao INT,                           -- Số lượng sản phẩm giao
    PRIMARY KEY (MaGiaoHang, IDSanPham),      -- Khóa chính là sự kết hợp của MaGiaoHang và IDSanPham
    FOREIGN KEY (MaGiaoHang) REFERENCES PhieuGiaoHang(MaGiaoHang),  -- Khóa ngoại tham chiếu đến MaGiaoHang trong PhieuGiaoHang
    FOREIGN KEY (IDSanPham) REFERENCES SanPham(IDSanPham)  -- Khóa ngoại tham chiếu đến IDSanPham trong SanPham
);
CREATE TABLE ChiTietHoanTra (
    MaPhieuTra CHAR(10),
    IDSanPham CHAR(10),
    SoLuong INT,
    LyDoChiTiet nVARCHAR(200),
    PRIMARY KEY (MaPhieuTra, IDSanPham),
    FOREIGN KEY (MaPhieuTra) REFERENCES PhieuHoanTra(MaChungTu),
    FOREIGN KEY (IDSanPham) REFERENCES SanPham(IDSanPham)
);
CREATE TABLE ChiTietTraHang (
    MaPhieuTra CHAR(10),
    IDSanPham CHAR(10),
    SoLuong INT CHECK (SoLuong > 0),
    LyDoChiTiet NVARCHAR(200),

    PRIMARY KEY (MaPhieuTra, IDSanPham),
    FOREIGN KEY (MaPhieuTra) REFERENCES PhieuTraHang(MaPhieuTra),
    FOREIGN KEY (IDSanPham) REFERENCES SanPham(IDSanPham)
);
INSERT INTO PhieuTraHang (MaPhieuTra, MaHoaDon, NgayTra, LyDo, TrangThai)
VALUES
('PT00000001', 'CT00000001', '2025-08-05', N'Lỗi kỹ thuật', N'Chờ xử lý'),
('PT00000002', 'CT00000002', '2025-08-05', N'Không đúng mẫu', N'Đã xử lý'),
('PT00000003', 'CT00000003', '2025-08-06', N'Không còn nhu cầu', N'Chờ xác nhận'),
('PT00000004', 'CT00000004', '2025-08-06', N'Hàng bị rách', N'Đã từ chối'),
('PT00000005', 'CT00000001', '2025-08-07', N'Lỗi sản xuất', N'Đã xử lý'),
('PT00000006', 'CT00000002', '2025-08-07', N'Khách đổi size', N'Chờ xử lý'),
('PT00000007', 'CT00000003', '2025-08-08', N'Không đúng màu', N'Chờ xác nhận'),
('PT00000008', 'CT00000004', '2025-08-08', N'Khách hàng thay đổi ý định', N'Đã xử lý'),
('PT00000009', 'CT00000005', '2025-08-09', N'Sản phẩm trầy xước', N'Chờ xử lý'),
('PT00000010', 'CT00000001', '2025-08-09', N'Sản phẩm bị lỗi nhẹ', N'Đã xử lý');
INSERT INTO ChiTietTraHang (MaPhieuTra, IDSanPham, SoLuong, LyDoChiTiet)
VALUES
('PT00000001', 'SP00000001', 1, N'Sản phẩm bị lỗi'),
('PT00000001', 'SP00000002', 2, N'Không đúng mẫu đặt'),
('PT00000002', 'SP00000003', 1, N'Khách không thích'),
('PT00000003', 'SP00000004', 2, N'Đổi size'),
('PT00000004', 'SP00000001', 5, N'Hàng bị rách nhẹ'),
('PT00000005', 'SP00000005', 8, N'Chưa mở bao bì'),
('PT00000006', 'SP00000002', 10, N'Khác với quảng cáo'),
('PT00000007', 'SP00000003', 2, N'Không hợp thời trang'),
('PT00000008', 'SP00000004', 1, N'Khách đổi sang sản phẩm khác'),
('PT00000010', 'SP00000001', 1, N'Sản phẩm bị trầy xước');
SELECT * 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME = 'PhieuTraHang';

go
ALTER TABLE HoaDon
ADD MaPhuongThucThanhToan CHAR(10),
    CONSTRAINT FK_HoaDon_PhuongThuc
    FOREIGN KEY (MaPhuongThucThanhToan) REFERENCES 
	PhuongThucThanhToan(MaPhuongThucThanhToan);
	go
	ALTER TABLE HoaDon

ADD IDKhachHang CHAR(10),
    CONSTRAINT FK_HoaDon_KhachHang
    FOREIGN KEY (IDKhachHang) REFERENCES KhachHang(IDKhachHang);
	go
CREATE TABLE KhoHang (
    MaKhoHang CHAR(10) PRIMARY KEY,
    TenKhoHang nVARCHAR(200) NOT NULL,
    DiaChiKho nvarCHAR(200),
    KhuVucPhucVu nVARCHAR(5)
);
CREATE TABLE SanPhamTrongKho (
    MaKhoHang CHAR(10),
    IDSanPham CHAR(10),
    SoLuongTon INT DEFAULT 0,
    PRIMARY KEY (MaKhoHang, IDSanPham),
    FOREIGN KEY (MaKhoHang) REFERENCES KhoHang(MaKhoHang),
    FOREIGN KEY (IDSanPham) REFERENCES SanPham(IDSanPham)
);
go
ALTER TABLE HoaDon
ADD CONSTRAINT FK_HoaDon_ChungTu
FOREIGN KEY (MaChungTu) REFERENCES ChungTu(MaChungTu);


go
INSERT INTO QuyenHan (MaQuyenHan, TenQuyenHan) VALUES
('QH00000001', N'Admin'),              -- Toàn quyền hệ thống
('QH00000002', N'Nhân viên bán hàng'), -- CSKH, xử lý đơn hàng, khách hàng
('QH00000003', N'Kế toán'),            -- Lập hóa đơn, báo cáo tài chính
('QH00000004', N'Thủ kho')            -- Quản lý kho, phiếu giao hàng, tồn kho
go
INSERT INTO NhanVien VALUES 
('NV00000001', N'Nguyễn Văn A', '1995-05-12', N'Nam', 'a.nguyen@example.com', '0901234567'),
('NV00000002', N'Trần Thị B', '1998-08-21', N'Nữ', 'b.tran@example.com', '0902345678'),
('NV00000003', N'Lê Văn C', '1990-01-10', N'Nam', 'c.le@example.com', '0903456789'),
('NV00000004', N'Phạm Thị D', '1988-03-25', N'Nữ', 'd.pham@example.com', '0904567890'),
('NV00000005', N'Hoàng Văn E', '1992-11-03', N'Nam', 'e.hoang@example.com', '0905678901'),
('NV00000006', N'Đặng Thị F', '1996-07-18', N'Nữ', 'f.dang@example.com', '0906789012'),
('NV00000007', N'Vũ Văn G', '1993-06-09', N'Nam', 'g.vu@example.com', '0907890123'),
('NV00000008', N'Ngô Thị H', '1997-04-04', N'Nữ', 'h.ngo@example.com', '0908901234'),
('NV00000009', N'Đỗ Văn I', '1991-12-15', N'Nam', 'i.do@example.com', '0909012345'),
('NV00000010', N'Bùi Thị J', '1989-09-20', N'Nữ', 'j.bui@example.com', '0910123456'),
('NV00000011', N'Mai Văn K', '1994-02-14', N'Nam', 'k.mai@example.com', '0911234567'),
('NV00000012', N'Tô Thị L', '1990-11-29', N'Nữ', 'l.to@example.com', '0912345678'),
('NV00000013', N'Dương Văn M', '1999-03-03', N'Nam', 'm.duong@example.com', '0913456789'),
('NV00000014', N'Huỳnh Thị N', '1995-06-30', N'Nữ', 'n.huynh@example.com', '0914567890'),
('NV00000015', N'Lý Văn O', '1987-08-08', N'Nam', 'o.ly@example.com', '0915678901'),
('NV00000016', N'Tống Thị P', '1996-01-22', N'Nữ', 'p.tong@example.com', '0916789012'),
('NV00000017', N'Kiều Văn Q', '1993-10-12', N'Nam', 'q.kieu@example.com', '0917890123'),
('NV00000018', N'Hứa Thị R', '1998-02-05', N'Nữ', 'r.hua@example.com', '0918901234'),
('NV00000019', N'La Văn S', '1990-05-16', N'Nam', 's.la@example.com', '0919012345'),
('NV00000020', N'Trương Thị T', '1997-12-01', N'Nữ', 't.truong@example.com', '0920123456');
INSERT INTO TaiKhoan (MaTaiKhoan, TenTaiKhoan, TenDangNhap, MatKhau, TrangThaiHoatDong) VALUES
('TK00000001', N'Nguyễn Văn A', 'a.nguyen', '123456', DEFAULT),
('TK00000002', N'Trần Thị B', 'b.tran', '654321', DEFAULT),
('TK00000003', N'Lê Văn C', 'c.le', 'abc123', DEFAULT),
('TK00000004', N'Phạm Thị D', 'd.pham', 'pass456', DEFAULT),
('TK00000005', N'Hoàng Văn E', 'e.hoang', 'qwerty', DEFAULT),
('TK00000006', N'Đặng Thị F', 'f.dang', 'f123456', DEFAULT),
('TK00000007', N'Vũ Văn G', 'g.vu', 'vu123456', DEFAULT),
('TK00000008', N'Ngô Thị H', 'h.ngo', 'h@123456', DEFAULT),
('TK00000009', N'Đỗ Văn I', 'i.do', 'i#987654', DEFAULT),
('TK00000010', N'Bùi Thị J', 'j.bui', 'jpass789', DEFAULT),
('TK00000011', N'Mai Văn K', 'k.mai', '123abc', DEFAULT),
('TK00000012', N'Tô Thị L', 'l.to', 'to@2024', DEFAULT),
('TK00000013', N'Dương Văn M', 'm.duong', 'duong01', DEFAULT),
('TK00000014', N'Huỳnh Thị N', 'n.huynh', 'pass1234', DEFAULT),
('TK00000015', N'Lý Văn O', 'o.ly', 'oly2024', DEFAULT),
('TK00000016', N'Tống Thị P', 'p.tong', 'tong789', DEFAULT),
('TK00000017', N'Kiều Văn Q', 'q.kieu', 'kieu321', DEFAULT),
('TK00000018', N'Hứa Thị R', 'r.hua', 'hua32145', DEFAULT),
('TK00000019', N'La Văn S', 's.la', 'la98765', DEFAULT),
('TK00000020', N'Trương Thị T', 't.truong', 'truong12', DEFAULT);
DECLARE @i INT = 1;
WHILE @i <= 20
BEGIN
    DECLARE @maTK CHAR(10) = 'TK' + RIGHT('0000000' + CAST(@i AS VARCHAR), 8);
    DECLARE @maNV CHAR(10) = 'NV' + RIGHT('0000000' + CAST(@i AS VARCHAR), 8);

    UPDATE TaiKhoan SET MaNhanVien = @maNV WHERE MaTaiKhoan = @maTK;

    SET @i += 1;
END

go

   
   -- Quản lý danh mục, sản phẩm, tồn kho
-- 5 tài khoản đầu: Admin
UPDATE TaiKhoan 
SET MaQuyenHan = 'QH00000001' 
WHERE MaTaiKhoan IN ('TK00000001', 'TK00000002', 'TK00000003', 'TK00000004', 'TK00000005');

-- 5 tài khoản tiếp theo: Nhân viên bán hàng
UPDATE TaiKhoan 
SET MaQuyenHan = 'QH00000002' 
WHERE MaTaiKhoan IN ('TK00000006', 'TK00000007', 'TK00000008', 'TK00000009', 'TK00000010');
go
-- 5 tài khoản tiếp theo: Kế toán
UPDATE TaiKhoan 
SET MaQuyenHan = 'QH00000003' 
WHERE MaTaiKhoan IN ('TK00000011', 'TK00000012', 'TK00000013', 'TK00000014', 'TK00000015');
go
-- 3 tài khoản tiếp theo: Thủ kho
UPDATE TaiKhoan 
SET MaQuyenHan = 'QH00000004' 
WHERE MaTaiKhoan IN ('TK00000016', 'TK00000017', 'TK00000018');
go
-- 2 tài khoản cuối: Quản lý sản phẩm
INSERT INTO DanhMucSanPham VALUES
('DM00000001', N'Áo thun'),
('DM00000002', N'Áo sơ mi'),
('DM00000003', N'Quần jeans'),
('DM00000004', N'Váy nữ'),
('DM00000005', N'Phụ kiện');
go
INSERT INTO PhuongThucThanhToan  VALUES
('PT00000001', N'Thanh toán tiền mặt'),
('PT00000002', N'Thanh toán chuyển khoản'),
('PT00000003', N'Thanh toán qua ví điện tử'),
('PT00000004', N'Thanh toán khi nhận hàng (COD)'),
('PT00000005', N'Thanh toán qua thẻ ngân hàng');
go
INSERT INTO SanPham (IDSanPham, TenSanPham, MoTa, MaDanhMucSanPham) VALUES
-- Áo thun
('SP00000001', N'Áo thun nam cổ tròn', N'Chất liệu cotton, màu trắng', 'DM00000001'),
('SP00000002', N'Áo thun nữ tay ngắn', N'Mềm mại, thấm hút tốt', 'DM00000001'),
('SP00000003', N'Áo thun unisex in hình', N'Màu đen, in hình hoạt hình', 'DM00000001'),
('SP00000004', N'Áo thun nam thể thao', N'Co giãn, thoáng khí', 'DM00000001'),

-- Áo sơ mi
('SP00000005', N'Áo sơ mi trắng nam', N'Form regular, vải kate', 'DM00000002'),
('SP00000006', N'Áo sơ mi nữ caro', N'Cổ trụ, tay dài', 'DM00000002'),
('SP00000007', N'Áo sơ mi linen tay lỡ', N'Màu pastel, mát mẻ', 'DM00000002'),
('SP00000008', N'Áo sơ mi công sở', N'Dành cho nhân viên văn phòng', 'DM00000002'),

-- Quần jeans
('SP00000009', N'Quần jeans nam slim fit', N'Co giãn nhẹ, màu xanh đậm', 'DM00000003'),
('SP00000010', N'Quần jeans nữ ống loe', N'Cạp cao, phong cách retro', 'DM00000003'),
('SP00000011', N'Quần jeans rách gối', N'Trẻ trung, năng động', 'DM00000003'),
('SP00000012', N'Quần baggy jeans', N'Form rộng, hợp thời trang', 'DM00000003'),

-- Váy nữ
('SP00000013', N'Váy xòe hoa nhí', N'Dịu dàng, phù hợp mùa hè', 'DM00000004'),
('SP00000014', N'Váy bodycon tay dài', N'Dự tiệc, màu đen', 'DM00000004'),
('SP00000015', N'Váy maxi 2 dây', N'Phong cách boho', 'DM00000004'),
('SP00000016', N'Chân váy chữ A', N'Phối với áo sơ mi nữ', 'DM00000004'),

-- Phụ kiện
('SP00000017', N'Nón lưỡi trai basic', N'Màu đen, chất kaki', 'DM00000005'),
('SP00000018', N'Túi đeo chéo vải bố', N'Nhỏ gọn, tiện dụng', 'DM00000005'),
('SP00000019', N'Thắt lưng da nam', N'Chất liệu da bò, bản 3.5cm', 'DM00000005'),
('SP00000020', N'Vớ thể thao cổ thấp', N'Gồm 3 đôi, thoáng khí', 'DM00000005');
go
INSERT INTO KhachHang  VALUES
('KH00000001', N'Nguyễn Thị Mai', 'mai01@gmail.com', N'Hà Nội', '0911000001'),
('KH00000002', N'Phạm Văn An', 'an02@gmail.com', N'Hồ Chí Minh', '0911000002'),
('KH00000003', N'Lê Thị Hoa', 'hoa03@gmail.com', N'Đà Nẵng', '0911000003'),
('KH00000004', N'Trần Văn Nam', 'nam04@gmail.com', N'Cần Thơ', '0911000004'),
('KH00000005', N'Vũ Thị Hạnh', 'hanh05@gmail.com', N'Hải Phòng', '0911000005'),
('KH00000006', N'Hồ Văn Phúc', 'phuc06@gmail.com', N'Nha Trang', '0911000006'),
('KH00000007', N'Bùi Thị Ngọc', 'ngoc07@gmail.com', N'Biên Hòa', '0911000007'),
('KH00000008', N'Đặng Văn Khoa', 'khoa08@gmail.com', N'Vũng Tàu', '0911000008'),
('KH00000009', N'Tô Thị Yến', 'yen09@gmail.com', N'Quảng Ninh', '0911000009'),
('KH00000010', N'Ngô Văn Khánh', 'khanh10@gmail.com', N'Hà Nam', '0911000010'),
('KH00000011', N'Mai Thị Hương', 'huong11@gmail.com', N'Thanh Hóa', '0911000011'),
('KH00000012', N'La Văn Hậu', 'hau12@gmail.com', N'Lâm Đồng', '0911000012'),
('KH00000013', N'Tống Thị Minh', 'minh13@gmail.com', N'Quảng Nam', '0911000013'),
('KH00000014', N'Kiều Văn Đông', 'dong14@gmail.com', N'Phú Thọ', '0911000014'),
('KH00000015', N'Hứa Thị Như', 'nhu15@gmail.com', N'Bình Dương', '0911000015'),
('KH00000016', N'Trương Văn Thịnh', 'thinh16@gmail.com', N'Huế', '0911000016'),
('KH00000017', N'Lý Thị Xuân', 'xuan17@gmail.com', N'Tây Ninh', '0911000017'),
('KH00000018', N'Thân Văn Bảo', 'bao18@gmail.com', N'Bình Thuận', '0911000018'),
('KH00000019', N'Đinh Thị Quỳnh', 'quynh19@gmail.com', N'Nam Định', '0911000019'),
('KH00000020', N'Châu Văn Sơn', 'son20@gmail.com', N'Hòa Bình', '0911000020');
SELECT * FROM KhachHang ORDER BY IDKhachHang;
go
DISABLE TRIGGER TR_Check_DonHang_PhaiCoChiTiet ON DonHang;
-- 2. Chèn dữ liệu vào bảng DonHang
INSERT INTO DonHang (MaDonHang, NgayDatHang, TrangThaiDonHang, IDKhachHang) VALUES
('DH00000001', '2025-08-01 10:00', N'Đã xác nhận', 'KH00000001'),
('DH00000002', '2025-08-01 11:30', N'Đang xử lý', 'KH00000002'),
('DH00000003', '2025-08-01 13:00', N'Đã giao hàng', 'KH00000003'),
('DH00000004', '2025-08-02 09:45', N'Đã hủy', 'KH00000004'),
('DH00000005', '2025-08-02 15:15', N'Đang xử lý', 'KH00000005'),
('DH00000006', '2025-08-03 08:00', N'Đã giao hàng', 'KH00000006'),
('DH00000007', '2025-08-03 10:30', N'Đã xác nhận', 'KH00000007'),
('DH00000008', '2025-08-03 14:00', N'Đang xử lý', 'KH00000008'),
('DH00000009', '2025-08-04 09:00', N'Đã giao hàng', 'KH00000009'),
('DH00000010', '2025-08-04 12:30', N'Đã hủy', 'KH00000010'),
('DH00000011', '2025-08-04 15:45', N'Đã xác nhận', 'KH00000011'),
('DH00000012', '2025-08-05 08:20', N'Đang xử lý', 'KH00000012'),
('DH00000013', '2025-08-05 10:10', N'Đã giao hàng', 'KH00000013'),
('DH00000014', '2025-08-05 13:40', N'Đã xác nhận', 'KH00000014'),
('DH00000015', '2025-08-06 09:00', N'Đã xác nhận', 'KH00000015'),
('DH00000016', '2025-08-06 11:15', N'Đã giao hàng', 'KH00000016'),
('DH00000017', '2025-08-06 14:00', N'Đã hủy', 'KH00000017'),
('DH00000018', '2025-08-07 08:45', N'Đã xác nhận', 'KH00000018'),
('DH00000019', '2025-08-07 11:20', N'Đang xử lý', 'KH00000019'),
('DH00000020', '2025-08-07 15:00', N'Đã giao hàng', 'KH00000020');
GO
SELECT * FROM DonHang WHERE MaDonHang = 'DH00000001';

-- 3. Chèn dữ liệu vào bảng ChiTietDonHang (giả định đã có sản phẩm SP0001 đến SP0020)
ENABLE TRIGGER TR_Check_DonHang_PhaiCoChiTiet ON DonHang;
GO
-- Bật lại trigger sau khi nhập dữ liệu
ENABLE TRIGGER TR_Check_HoaDon_PhaiCoDonHang ON HoaDon;

go
SELECT dh.MaDonHang, dh.NgayDatHang, dh.TrangThaiDonHang, kh.HoTen
FROM DonHang dh
JOIN KhachHang kh ON dh.IDKhachHang = kh.IDKhachHang
ORDER BY dh.MaDonHang;

INSERT INTO ChungTu (MaChungTu, TenChungTu, NgayLap) VALUES
('CT00000006', N'Đơn hàng', '2025-08-04 09:00'),
('CT00000007', N'Đơn hàng', '2025-08-04 10:15'),
('CT00000008', N'Đơn hàng', '2025-08-04 11:00');
SELECT * FROM ChungTu;
INSERT INTO ChungTu (MaChungTu, TenChungTu, NgayLap) VALUES
('CT00000001', N'Hóa đơn', '2025-08-01'),
('CT00000002', N'Hóa đơn', '2025-08-02'),
('CT00000003', N'Hóa đơn', '2025-08-03'),
('CT00000004', N'Hóa đơn', '2025-08-04'),
('CT00000005', N'Hóa đơn', '2025-08-05');
enABLE TRIGGER TR_Check_HoaDon_PhaiCoDonHang ON HoaDon;

INSERT INTO HoaDon  VALUES
('CT00000001', N'Đã TT',    'PT00000001', 'KH00000001'),
('CT00000002', N'Chưa TT',  'PT00000002', 'KH00000002'),
('CT00000003', N'Đang TT',  'PT00000003', 'KH00000003'),
('CT00000004', N'Đã TT',    'PT00000004', 'KH00000004'),
('CT00000005', N'Hủy',      'PT00000005', 'KH00000005');
-- Kiểm tra đơn hàng có chưa
SELECT * FROM DonHang WHERE MaDonHang = 'PT00000001';

-- Kiểm tra khách hàng có chưa
SELECT * FROM KhachHang WHERE IDKhachHang = 'KH00000001';

-- Thử chèn 1 hóa đơn đơn lẻ
INSERT INTO HoaDon VALUES ('CT00000001', N'Đã TT', 'PT00000001', 'KH00000001');
-- Tạm ngưng trigger
DISABLE TRIGGER TR_Check_HoaDon_PhaiCoDonHang ON HoaDon;


INSERT INTO KhoHang (MaKhoHang, TenKhoHang, DiaChiKho, KhuVucPhucVu) VALUES
('KHO000001', N'Kho trung tâm Hà Nội', 'Số 1 Trần Duy Hưng, Hà Nội', 'HN'),
('KHO000002', N'Kho miền Nam', '123 Lê Lợi, TP.HCM', 'SG'),
('KHO000003', N'Kho miền Trung', '45 Trần Phú, Đà Nẵng', 'MT'),
('KHO000004', N'Kho giao hàng nhanh', 'KCN Tân Tạo, TP.HCM', 'SG'),
('KHO000005', N'Kho Hà Nam', 'KCN Đồng Văn, Hà Nam', 'HN');
DELETE FROM KhoHang WHERE MaKhoHang = 'KHO000001';
DELETE FROM KhoHang
WHERE MaKhoHang IN ('KHO000002', 'KHO000003', 'KHO000004', 'KHO000005');

DELETE FROM SanPhamTrongKho
WHERE (MaKhoHang = 'KHO000001' AND IDSanPham IN ('SP00000001', 'SP00000002'))
   OR (MaKhoHang = 'KHO000002' AND IDSanPham = 'SP00000001')
   OR (MaKhoHang = 'KHO000003' AND IDSanPham = 'SP00000003')
   OR (MaKhoHang = 'KHO000005' AND IDSanPham = 'SP00000004');

INSERT INTO SanPhamTrongKho (MaKhoHang, IDSanPham, SoLuongTon) VALUES
('KHO000001', 'SP00000001', 100),
('KHO000001', 'SP00000002', 500),
('KHO000002', 'SP00000001', 300),
('KHO000003', 'SP00000003', 600),
('KHO000005', 'SP00000004', 205);
SELECT kh.TenKhoHang, sp.TenSanPham, stk.SoLuongTon
FROM SanPhamTrongKho stk
JOIN KhoHang kh ON stk.MaKhoHang = kh.MaKhoHang
JOIN SanPham sp ON stk.IDSanPham = sp.IDSanPham
ORDER BY kh.TenKhoHang;
INSERT INTO ChiTietDonHang (MaDonHang, IDSanPham, SoLuong, DonGia) VALUES
('DH00000001', 'SP00000001', 2, 199000),
('DH00000001', 'SP00000005', 1, 299000),
('DH00000002', 'SP00000002', 3, 189000),
('DH00000002', 'SP00000009', 1, 399000),
('DH00000003', 'SP00000003', 2, 229000),
('DH00000003', 'SP00000006', 1, 249000),
('DH00000004', 'SP00000004', 2, 259000),
('DH00000005', 'SP00000007', 1, 279000),
('DH00000006', 'SP00000008', 3, 199000),
('DH00000007', 'SP00000010', 1, 349000),
('DH00000008', 'SP00000011', 2, 319000),
('DH00000009', 'SP00000012', 1, 359000),
('DH00000010', 'SP00000013', 1, 289000),
('DH00000011', 'SP00000014', 2, 369000),
('DH00000012', 'SP00000015', 1, 399000),
('DH00000013', 'SP00000016', 2, 209000),
('DH00000014', 'SP00000017', 1, 149000),
('DH00000015', 'SP00000018', 2, 189000),
('DH00000016', 'SP00000019', 1, 249000),
('DH00000017', 'SP00000020', 3, 99000);
--ENABLE TRIGGER ALL ON ChiTietHoaDon;


INSERT INTO ChiTietHoaDon (MaHoaDon, IDSanPham, SoLuong, DonGia) VALUES
('CT00000001', 'SP00000001', 2, 199000),
('CT00000001', 'SP00000005', 1, 299000),
('CT00000002', 'SP00000002', 3, 189000),
('CT00000002', 'SP00000009', 1, 399000),
('CT00000003', 'SP00000003', 2, 229000),
('CT00000003', 'SP00000006', 1, 249000),
('CT00000004', 'SP00000004', 2, 259000),
('CT00000005', 'SP00000007', 1, 279000),
('CT00000001', 'SP00000008', 3, 199000),
('CT00000001', 'SP00000010', 1, 349000),
('CT00000002', 'SP00000011', 2, 319000),
('CT00000002', 'SP00000012', 1, 359000),
('CT00000003', 'SP00000013', 1, 289000),
('CT00000003', 'SP00000014', 2, 369000),
('CT00000004', 'SP00000015', 1, 399000),
('CT00000004', 'SP00000016', 2, 209000),
('CT00000005', 'SP00000017', 1, 149000),
('CT00000005', 'SP00000018', 2, 189000),
('CT00000005', 'SP00000019', 1, 249000),
('CT00000005', 'SP00000020', 3, 99000);
SELECT MaChungTu FROM PhieuHoanTra;
INSERT INTO ChungTu (MaChungTu, TenChungTu, NgayLap) VALUES
('CT00000009', N'Phiếu hoàn trả', '2025-08-05'),
('CT00000010', N'Phiếu hoàn trả', '2025-08-05'),
('CT00000011', N'Phiếu hoàn trả', '2025-08-05');
INSERT INTO PhieuHoanTra (MaChungTu, NgayTra, LyDo, TrangThai) VALUES
('CT00000009', '2025-08-05', N'Lỗi kỹ thuật', N'Chờ xử lý'),
('CT00000010', '2025-08-05', N'Không đúng size', N'Đã xử lý'),
('CT00000011', '2025-08-05', N'Khách không còn nhu cầu', N'Chờ xác nhận');
DISABLE TRIGGER ALL ON ChiTietHoanTra;
ENABLE TRIGGER ALL ON ChiTietHoantra;
INSERT INTO ChiTietHoanTra (MaPhieuTra, IDSanPham, SoLuong, LyDoChiTiet) VALUES
('CT00000009', 'SP00000001', 1, N'Sản phẩm bị lỗi'),
('CT00000009', 'SP00000005', 2, N'Không đúng mẫu đặt'),
('CT00000010', 'SP00000009', 5, N'Khách đổi size'),
('CT00000010', 'SP00000011', 1, N'Vải bị rách nhẹ'),
('CT00000011', 'SP00000014', 4, N'Không còn nhu cầu');
INSERT INTO ChungTu (MaChungTu, TenChungTu, NgayLap) VALUES
('CT00000012', N'Phiếu giao hàng', '2025-08-05'),
('CT00000013', N'Phiếu giao hàng', '2025-08-05'),
('CT00000014', N'Phiếu giao hàng', '2025-08-06'),
('CT00000015', N'Phiếu giao hàng', '2025-08-06'),
('CT00000016', N'Phiếu giao hàng', '2025-08-07');
-- Trong các bảng con như HoaDon, PhieuHoanTra, PhieuGiaoHang:
--PhieuGiaoHang
--chitietphieugiaohang
INSERT INTO ChungTu (MaChungTu, TenChungTu, NgayLap) VALUES
('CTGH00001', N'Phiếu giao hàng đơn hàng DH000001', '2025-08-05'),
('CTGH00002', N'Phiếu giao hàng đơn hàng DH000002', '2025-08-05');
INSERT INTO PhieuGiaoHang  VALUES
('CTGH00001', '2025-08-06 09:00', 'DH00000001'),
('CTGH00002', '2025-08-06 14:00', 'DH00000002');

SELECT * FROM DonHang WHERE MaDonHang = 'DH00000001';
SELECT * FROM ChungTu WHERE MaChungTu = 'CTGH00001';
SELECT * FROM SanPham WHERE IDSanPham = 'SP00000001';
DROP TABLE ChiTietPhieuGiaoHang;
CREATE TABLE ChiTietPhieuGiaoHang (
    MaGiaoHang CHAR(10),  -- Mã phiếu giao hàng, tham chiếu từ PhieuGiaoHang
    IDSanPham CHAR(10),   -- Mã sản phẩm, tham chiếu từ SanPham
    SoLuongGiao INT,      -- Số lượng giao
    PRIMARY KEY (MaGiaoHang, IDSanPham),  -- Khóa chính là sự kết hợp của MaGiaoHang và IDSanPham
    FOREIGN KEY (MaGiaoHang) REFERENCES PhieuGiaoHang(MaGiaoHang),  -- Khóa ngoại tham chiếu đến MaGiaoHang trong PhieuGiaoHang
    FOREIGN KEY (IDSanPham) REFERENCES SanPham(IDSanPham)  -- Khóa ngoại tham chiếu đến IDSanPham trong SanPham
);
INSERT INTO ChiTietPhieuGiaoHang  VALUES
('CTGH00001', 'SP00000001', 3),
('CTGH00001', 'SP00000002', 2),
('CTGH00002', 'SP00000001', 1);
-- Bước 1: Xoá ràng buộc cũ nếu có
ALTER TABLE SanPham
DROP CONSTRAINT FK_SanPham_DanhMuc;

-- Bước 2: Tạo lại với ON DELETE CASCADE
ALTER TABLE SanPham
ADD CONSTRAINT FK_SanPham_DanhMuc
FOREIGN KEY (MaDanhMucSanPham)
REFERENCES DanhMucSanPham(MaDanhMucSanPham)
ON DELETE CASCADE;
ALTER TABLE SanPham
ADD DonGia DECIMAL(18, 2);
UPDATE SanPham SET DonGia = 199000 WHERE IDSanPham = 'SP00000001';
UPDATE SanPham SET DonGia = 259000 WHERE IDSanPham = 'SP00000002';
UPDATE SanPham SET DonGia = 299000 WHERE IDSanPham = 'SP00000003';
UPDATE SanPham SET DonGia = 229000 WHERE IDSanPham = 'SP00000004';
UPDATE SanPham SET DonGia = 399000 WHERE IDSanPham = 'SP00000005';
UPDATE SanPham SET DonGia = 549000 WHERE IDSanPham = 'SP00000006';
UPDATE SanPham SET DonGia = 189000 WHERE IDSanPham = 'SP00000007';
UPDATE SanPham SET DonGia = 159000 WHERE IDSanPham = 'SP00000008';
UPDATE SanPham SET DonGia = 129000 WHERE IDSanPham = 'SP00000009';
UPDATE SanPham SET DonGia = 179000 WHERE IDSanPham = 'SP00000010';
UPDATE SanPham SET DonGia = 369000 WHERE IDSanPham = 'SP00000011';
UPDATE SanPham SET DonGia = 149000 WHERE IDSanPham = 'SP00000012';
UPDATE SanPham SET DonGia = 279000 WHERE IDSanPham = 'SP00000013';
UPDATE SanPham SET DonGia = 139000 WHERE IDSanPham = 'SP00000014';
UPDATE SanPham SET DonGia = 319000 WHERE IDSanPham = 'SP00000015';
UPDATE SanPham SET DonGia = 249000 WHERE IDSanPham = 'SP00000016';
UPDATE SanPham SET DonGia = 299000 WHERE IDSanPham = 'SP00000017';
UPDATE SanPham SET DonGia = 269000 WHERE IDSanPham = 'SP00000018';
UPDATE SanPham SET DonGia = 339000 WHERE IDSanPham = 'SP00000019';
UPDATE SanPham SET DonGia = 99000  WHERE IDSanPham = 'SP00000020';
SELECT IDSanPham, TenSanPham, DonGia FROM SanPham WHERE IDSanPham LIKE 'SP000000%';
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DonHang'
SELECT * 
FROM DonHang d
WHERE d.MaChungTu IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM ChungTu c WHERE c.MaChungTu = d.MaChungTu
  );

ALTER TABLE DonHang ADD MaChungTu CHAR(10)
ALTER TABLE DonHang
ADD CONSTRAINT FK_DonHang_ChungTu
FOREIGN KEY (MaChungTu) REFERENCES ChungTu(MaChungTu)

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DonHang' AND COLUMN_NAME = 'MaChungTu';
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ChungTu' AND COLUMN_NAME = 'MaChungTu';
-- Bước 1: Drop FK nếu đã tạo
ALTER TABLE DonHang DROP CONSTRAINT IF EXISTS FK_DonHang_ChungTu;

-- Bước 2: Đổi kiểu MaChungTu ở bảng DonHang về char(10)
ALTER TABLE DonHang
ALTER COLUMN MaChungTu CHAR(10);

-- Bước 3: Tạo lại Foreign Key
ALTER TABLE DonHang
ADD CONSTRAINT FK_DonHang_ChungTu
FOREIGN KEY (MaChungTu)
REFERENCES ChungTu(MaChungTu);

WITH DonHang_Stt AS (
    SELECT MaDonHang, ROW_NUMBER() OVER (ORDER BY MaDonHang) AS stt
    FROM DonHang
    WHERE MaChungTu IS NULL
),
ChungTu_Stt AS (
    SELECT MaChungTu, ROW_NUMBER() OVER (ORDER BY MaChungTu) AS stt
    FROM ChungTu
    WHERE TenChungTu = N'Hóa đơn'
)

ALTER TRIGGER TR_Check_HoaDon_PhaiCoDonHang
ON HoaDon
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN DonHang dh ON i.MaChungTu = dh.MaChungTu
        WHERE i.MaChungTu IS NOT NULL AND dh.MaChungTu IS NULL
    )
    BEGIN
        RAISERROR(N'Lỗi: Hóa đơn phải gắn với một đơn hàng hợp lệ.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END
ALTER TABLE DonHang
ALTER COLUMN MaChungTu CHAR(10) NULL;

SELECT COLUMN_NAME, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DonHang' AND COLUMN_NAME = 'MaChungTu';
UPDATE DonHang
SET MaChungTu = NULL
WHERE MaChungTu IS NOT NULL;
SELECT * FROM ChungTu WHERE MaChungTu NOT LIKE 'CT________'
ALTER TABLE PhieuGiaoHang
ADD TrangThaiGiao NVARCHAR(50) DEFAULT N'Chưa giao';
SELECT MaDonHang
FROM DonHang
WHERE MaChungTu IS NOT NULL
AND MaDonHang NOT IN (SELECT MaDonHang FROM PhieuGiaoHang);
SELECT MaDonHang, MaChungTu FROM DonHang WHERE MaChungTu IS NOT NULL

INSERT INTO ChungTu (MaChungTu, NgayLap)
VALUES 
('CT00000050', GETDATE()),
('CT00000051', GETDATE()),
('CT00000052', GETDATE()),
('CT00000053', GETDATE()),
('CT00000054', GETDATE()),
('CT00000055', GETDATE()),
('CT00000056', GETDATE()),
('CT00000057', GETDATE()),
('CT00000058', GETDATE()),
('CT00000059', GETDATE());
INSERT INTO DonHang (MaDonHang, IDKhachHang, MaChungTu, NgayDatHang)
VALUES 
('DH00000001', 'KH00000001', 'CT00000050', GETDATE()),
('DH00000002', 'KH00000002', 'CT00000051', GETDATE()),
('DH00000003', 'KH00000003', 'CT00000052', GETDATE()),
('DH00000004', 'KH00000004', 'CT00000053', GETDATE()),
('DH00000005', 'KH00000005', 'CT00000054', GETDATE()),
('DH00000006', 'KH00000006', 'CT00000055', GETDATE()),
('DH00000007', 'KH00000007', 'CT00000056', GETDATE()),
('DH00000008', 'KH00000008', 'CT00000057', GETDATE()),
('DH00000009', 'KH00000009', 'CT00000058', GETDATE()),
('DH00000010', 'KH00000010', 'CT00000059', GETDATE());
-- Sử dụng từ DH00000100 trở đi
enABLE TRIGGER TR_Check_DonHang_PhaiCoChiTiet ON DonHang;

INSERT INTO DonHang (MaDonHang, IDKhachHang, MaChungTu, NgayDatHang)
VALUES 
('DH00000100', 'KH00000001', 'CT00000050', GETDATE()),
('DH00000101', 'KH00000002', 'CT00000051', GETDATE()),
('DH00000102', 'KH00000003', 'CT00000052', GETDATE()),
('DH00000103', 'KH00000004', 'CT00000053', GETDATE()),
('DH00000104', 'KH00000005', 'CT00000054', GETDATE()),
('DH00000105', 'KH00000006', 'CT00000055', GETDATE()),
('DH00000106', 'KH00000007', 'CT00000056', GETDATE()),
('DH00000107', 'KH00000008', 'CT00000057', GETDATE()),
('DH00000108', 'KH00000009', 'CT00000058', GETDATE()),
('DH00000109', 'KH00000010', 'CT00000059', GETDATE());
-- 1. DonHang
INSERT INTO DonHang (MaDonHang, IDKhachHang, MaChungTu, NgayDatHang)
VALUES ('DH00000060', 'KH00000050', 'CT00000050', GETDATE());

-- 2. ChiTietDonHang
INSERT INTO ChiTietDonHang (MaDonHang, IDSanPham, SoLuong, DonGia)
VALUES ('DH00000060', 'SP0001', 2, 150000);
INSERT INTO ChiTietHoaDon 
VALUES
('CT00000050', 'SP00000001', 2, 199000),
('CT00000050', 'SP00000005', 1, 299000),
('CT00000051', 'SP00000002', 3, 189000),
('CT00000051', 'SP00000009', 1, 399000),
('CT00000052', 'SP00000003', 2, 229000),
('CT00000052', 'SP00000004', 5, 150000),
('CT00000053', 'SP00000006', 1, 249000),
('CT00000053', 'SP00000007', 3, 199000),
('CT00000054', 'SP00000001', 2, 199000),
('CT00000054', 'SP00000008', 4, 349000);
-- Chèn vào bảng HoaDon các mã hóa đơn từ CT00000050 đến CT00000054
SELECT MaChungTu FROM HoaDon WHERE MaChungTu IN ('CT00000050', 'CT00000051', 'CT00000052', 'CT00000053', 'CT00000054');
-- Chèn vào bảng HoaDon với trạng thái thanh toán và phương thức thanh toán bằng tiếng Việt,
-- IDKhachHang từ 50 trở đi và MaChungTu từ CT00000050 trở đi
ALTER TABLE HoaDon
ALTER COLUMN TrangThaiThanhToan VARCHAR(50); -- Hoặc VARCHAR(MAX)

-- Chèn vào bảng HoaDon với MaChungTu bắt đầu từ CT00000050 và MaKhachHang từ KH00000050
INSERT INTO HoaDon (MaChungTu, TrangThaiThanhToan, MaPhuongThucThanhToan, IDKhachHang)
VALUES 
('CT00000050', 'Đã thanh toán', 'PT00000001', 'KH00000050'),
('CT00000051', 'Chưa thanh toán', 'PT00000002', 'KH00000051'),
('CT00000052', 'Đang thanh toán', 'PT00000003', 'KH00000052'),
('CT00000053', 'Đã thanh toán', 'PT00000004', 'KH00000053'),
('CT00000054', 'Đã huỷ', 'PT00000005', 'KH00000054');

-- Chèn dữ liệu vào bảng KhachHang
-- Chèn dữ liệu vào bảng KhachHang từ IDKhachHang bắt đầu từ KH00000050
INSERT INTO KhachHang (IDKhachHang, HoTen, EmailKH, DiaChiKH, SDT)
VALUES
('KH00000050', 'Nguyen Thi Lan', 'lan50@gmail.com', 'Hanoi', '0911000010'),
('KH00000051', 'Pham Minh Thao', 'thao51@gmail.com', 'Ho Chi Minh', '0911000011'),
('KH00000052', 'Le Thi Thanh', 'thanh52@gmail.com', 'Da Nang', '0911000012'),
('KH00000053', 'Tran Thi Mai', 'mai53@gmail.com', 'Can Tho', '0911000013'),
('KH00000054', 'Trinh Thi Hoa', 'hoa54@gmail.com', 'Hai Phong', '0911000014'),
('KH00000055', 'Ho Thi Ngoc', 'ngoc55@gmail.com', 'Nha Trang', '0911000015'),
('KH00000056', 'Bui Thi Lan', 'lan56@gmail.com', 'Bien Hoa', '0911000016'),
('KH00000057', 'Dang Thi Hien', 'hien57@gmail.com', 'Vung Tau', '0911000017'),
('KH00000058', 'Nguyen Thi My', 'my58@gmail.com', 'Quang Ninh', '0911000018'),
('KH00000059', 'Le Thi Kim', 'kim59@gmail.com', 'Vinh Long', '0911000019');
-- Đổi tên cột MaChungTu thành MaGiaoHang trong bảng PhieuGiaoHang
EXEC sp_rename 'PhieuGiaoHang.MaChungTu', 'MaGiaoHang', 'COLUMN';
ALTER TABLE PhieuGiaoHang
DROP CONSTRAINT FK_PhieuGiaoHang_ChungTu;
UPDATE DonHang
SET MaGiaoHang = PhieuGiaoHang.MaGiaoHang
FROM DonHang dh
JOIN PhieuGiaoHang pg ON dh.MaDonHang = pg.MaDonHang;
SELECT * FROM ChungTu WHERE MaChungTu = 'CT00000052';
ALTER TABLE PhieuGiaoHang
DROP CONSTRAINT IF EXISTS FK_PhieuGiaoHang_ChungTu;
SELECT * FROM ChungTu WHERE MaChungTu = 'CT00000001'; -- Thay thế MaChungTu thực tế


INSERT INTO PhieuGiaoHang (MaGiaoHang, NgayGiao, MaDonHang, TrangThaiGiao)
VALUES 
('GH00000001', '2025-08-01 10:00', 'DH00000001', N'Chưa giao'),
('GH00000002', '2025-08-01 11:00', 'DH00000002', N'Đã giao');
INSERT INTO ChiTietPhieuGiaoHang (MaGiaoHang, IDSanPham, SoLuongGiao)
VALUES
('GH00000001', 'SP00000001', 2),
('GH00000001', 'SP00000002', 1),
('GH00000002', 'SP00000003', 3);
INSERT INTO PhieuGiaoHang (MaGiaoHang, MaDonHang, NgayGiao, TrangThaiGiao)
VALUES
('GH00000003', 'DH00000003', '2025-08-01 12:00', 'Giao ngay'),
('GH00000004', 'DH00000004', '2025-08-01 13:00', 'Giao ngay'),
('GH00000005', 'DH00000005', '2025-08-01 14:00', 'Giao ngay'),
('GH00000006', 'DH00000006', '2025-08-02 10:00', 'Giao ngay'),
('GH00000007', 'DH00000007', '2025-08-02 11:00', 'Giao ngay'),
('GH00000008', 'DH00000008', '2025-08-02 12:00', 'Giao ngay'),
('GH00000009', 'DH00000009', '2025-08-02 13:00', 'Giao ngay'),
('GH00000010', 'DH00000010', '2025-08-02 14:00', 'Giao ngay');
INSERT INTO ChiTietPhieuGiaoHang (MaGiaoHang, IDSanPham, SoLuongGiao)
VALUES
('GH00000002', 'SP00000004', 1),
('GH00000003', 'SP00000005', 2),
('GH00000003', 'SP00000006', 5),
('GH00000004', 'SP00000007', 3),
('GH00000004', 'SP00000008', 2),
('GH00000005', 'SP00000009', 4),
('GH00000005', 'SP00000010', 2),
('GH00000006', 'SP00000011', 1),
('GH00000006', 'SP00000012', 3),
('GH00000007', 'SP00000013', 5),
('GH00000007', 'SP00000014', 2),
('GH00000008', 'SP00000015', 4),
('GH00000008', 'SP00000016', 3),
('GH00000009', 'SP00000017', 2),
('GH00000009', 'SP00000018', 5),
('GH00000010', 'SP00000019', 3),
('GH00000010', 'SP00000020', 2);
SELECT MaDonHang FROM DonHang WHERE TrangThaiDonHang != N'N/A'
-- Xóa bảng chi tiết trước (nếu tồn tại)
DROP TABLE IF EXISTS ChiTietPhieuTra;
-- Xóa bảng chính
DROP TABLE IF EXISTS PhieuTraHang;
DROP TABLE IF EXISTS ChiTietPhieuTra;
DROP TABLE IF EXISTS PhieuTraHang;
-- Xóa bảng nếu đã tồn tại
DROP TABLE IF EXISTS PhieuTraHang;

ALTER TABLE PhieuHoanTra
DROP CONSTRAINT FK_PhieuHoan_MaChungtu__5DCAEF64;
DROP TABLE PhieuHoanTra;
SELECT 
        CAST(ct.NgayLap AS DATE) AS Ngay,
        SUM(cthd.SoLuong * cthd.DonGia) AS DoanhThu
    FROM ChungTu ct
    JOIN HoaDon hd ON ct.MaChungTu = hd.MaChungTu
    JOIN ChiTietHoaDon cthd ON hd.MaChungTu = cthd.MaHoaDon
    WHERE ct.NgayLap BETWEEN '09-06-2024' AND '09-08-2025'
    GROUP BY CAST(ct.NgayLap AS DATE)
    ORDER BY Ngay DESC;
	SELECT 
        sp.TenSanPham,
        SUM(cthd.SoLuong) AS SoLuongBan
    FROM ChungTu ct
    JOIN HoaDon hd ON ct.MaChungTu = hd.MaChungTu
    JOIN ChiTietHoaDon cthd ON hd.MaChungTu = cthd.MaHoaDon
    JOIN SanPham sp ON cthd.IDSanPham = sp.IDSanPham
    WHERE ct.NgayLap BETWEEN '09-06-2024' AND '09-08-2025'
    GROUP BY sp.TenSanPham
    ORDER BY SoLuongBan DESC;
		SELECT 
    dh.TrangThaiDonHang,
    COUNT(dh.MaDonHang) AS SoLuongDonHang
FROM DonHang dh
WHERE dh.NgayDatHang BETWEEN  '09-06-2024' AND '09-08-2025'
  AND dh.TrangThaiDonHang IS NOT NULL  -- Loại bỏ trạng thái NULL
GROUP BY dh.TrangThaiDonHang
ORDER BY SoLuongDonHang DESC;
