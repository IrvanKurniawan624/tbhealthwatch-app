using Microsoft.EntityFrameworkCore;
using TBHealthWatch.Domain.Entities;

namespace TBHealthWatch.Infrastructure.Persistence;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Region> Regions => Set<Region>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Patient> Patients => Set<Patient>();
    public DbSet<MedicationAdherence> MedicationAdherences => Set<MedicationAdherence>();
    public DbSet<AdherenceLog> AdherenceLogs => Set<AdherenceLog>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Region>().ToTable("regions");
        modelBuilder.Entity<User>().ToTable("users");
        modelBuilder.Entity<Patient>().ToTable("patients");
        modelBuilder.Entity<MedicationAdherence>().ToTable("medication_adherence");
        modelBuilder.Entity<AdherenceLog>().ToTable("adherence_logs");
        modelBuilder.Entity<RefreshToken>().ToTable("refresh_tokens");

        modelBuilder.Entity<User>().HasIndex(u => u.Email).IsUnique();

        modelBuilder.Entity<Patient>().HasQueryFilter(p => p.DeletedAt == null);
        modelBuilder.Entity<Patient>().HasIndex(p => p.Nik).IsUnique();
        modelBuilder.Entity<Patient>().Property(p => p.Gender).HasColumnType("char(1)");

        // EFCore.NamingConventions converts Phase1 → phase1 (no underscore before digit).
        // Manually override to match the schema's phase_1_start_date pattern.
        modelBuilder.Entity<MedicationAdherence>()
            .Property(x => x.Phase1StartDate).HasColumnName("phase_1_start_date");
        modelBuilder.Entity<MedicationAdherence>()
            .Property(x => x.Phase1EndDate).HasColumnName("phase_1_end_date");
        modelBuilder.Entity<MedicationAdherence>()
            .Property(x => x.Phase2StartDate).HasColumnName("phase_2_start_date");
        modelBuilder.Entity<MedicationAdherence>()
            .Property(x => x.Phase2EndDate).HasColumnName("phase_2_end_date");
        modelBuilder.Entity<MedicationAdherence>()
            .Property(x => x.TreatmentCompletedDate).HasColumnName("treatment_completed_date");

        modelBuilder.Entity<RefreshToken>().HasIndex(r => r.TokenHash).IsUnique();

        modelBuilder.Entity<User>()
            .HasOne(u => u.Region).WithMany()
            .HasForeignKey(u => u.RegionId).OnDelete(DeleteBehavior.SetNull);

        modelBuilder.Entity<Patient>()
            .HasOne(p => p.Region).WithMany()
            .HasForeignKey(p => p.RegionId).OnDelete(DeleteBehavior.SetNull);

        modelBuilder.Entity<RefreshToken>()
            .HasOne(r => r.User).WithMany()
            .HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<MedicationAdherence>()
            .HasOne(m => m.Patient).WithMany(p => p.MedicationAdherences)
            .HasForeignKey(m => m.PatientId).OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<AdherenceLog>()
            .HasOne(a => a.MedicationAdherence).WithMany(m => m.AdherenceLogs)
            .HasForeignKey(a => a.MedicationAdherenceId).OnDelete(DeleteBehavior.Cascade);
    }
}
