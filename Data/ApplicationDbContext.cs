using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using TranMinhKhoi.Models;

namespace TranMinhKhoi.Data;

public class ApplicationDbContext : IdentityDbContext<AppUser>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

    public DbSet<PhongBan> PhongBans => Set<PhongBan>();
    public DbSet<CaLamViec> CaLamViecs => Set<CaLamViec>();
    public DbSet<ViTriChamCong> ViTriChamCongs => Set<ViTriChamCong>();
    public DbSet<NhanVien> NhanViens => Set<NhanVien>();
    public DbSet<ChamCong> ChamCongs => Set<ChamCong>();
    public DbSet<DonNghiPhep> DonNghiPheps => Set<DonNghiPhep>();
    public DbSet<OtpCode> OtpCodes => Set<OtpCode>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<AppUser>().Property(u => u.HoTen).HasMaxLength(100);
        builder.Entity<AppUser>().Property(u => u.DeviceId).HasMaxLength(100);

        builder.Entity<NhanVien>(e =>
        {
            e.HasIndex(x => x.MaNV).IsUnique();
            e.HasIndex(x => x.UserId).IsUnique();
            e.Property(x => x.LuongCoBan).HasColumnType("decimal(18,2)");
            e.HasOne(x => x.PhongBan).WithMany(p => p.NhanViens)
                .HasForeignKey(x => x.PhongBanId).OnDelete(DeleteBehavior.SetNull);
            e.HasOne(x => x.CaLamViec).WithMany()
                .HasForeignKey(x => x.CaLamViecId).OnDelete(DeleteBehavior.SetNull);
            e.HasOne(x => x.User).WithMany()
                .HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.SetNull);
        });

        builder.Entity<ChamCong>(e =>
        {
            e.HasIndex(x => new { x.NhanVienId, x.Ngay }).IsUnique();
            e.HasOne(x => x.NhanVien).WithMany()
                .HasForeignKey(x => x.NhanVienId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.ViTriChamCong).WithMany()
                .HasForeignKey(x => x.ViTriChamCongId).OnDelete(DeleteBehavior.SetNull);
        });

        builder.Entity<DonNghiPhep>(e =>
        {
            e.HasOne(x => x.NhanVien).WithMany()
                .HasForeignKey(x => x.NhanVienId).OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<OtpCode>(e => e.HasIndex(x => new { x.UserId, x.MucDich }));
    }
}
