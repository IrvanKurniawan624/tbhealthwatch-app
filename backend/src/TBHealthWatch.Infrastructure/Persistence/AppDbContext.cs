using Microsoft.EntityFrameworkCore;
using TBHealthWatch.Domain.Entities;

namespace TBHealthWatch.Infrastructure.Persistence;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Region> Regions => Set<Region>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Patient> Patients => Set<Patient>();
    public DbSet<PatientTreatment> PatientTreatments => Set<PatientTreatment>();
    public DbSet<Medication> Medications => Set<Medication>();
    public DbSet<DailyMedicationTarget> DailyMedicationTargets => Set<DailyMedicationTarget>();
    public DbSet<DailyMedicationTargetItem> DailyMedicationTargetItems => Set<DailyMedicationTargetItem>();
    public DbSet<PatientMedicationLog> PatientMedicationLogs => Set<PatientMedicationLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Map to PostgreSQL snake_case table names
        modelBuilder.Entity<Region>().ToTable("regions");
        modelBuilder.Entity<User>().ToTable("users");
        modelBuilder.Entity<Patient>().ToTable("patients");
        modelBuilder.Entity<PatientTreatment>().ToTable("patient_treatments");
        modelBuilder.Entity<Medication>().ToTable("medications");
        modelBuilder.Entity<DailyMedicationTarget>().ToTable("daily_medication_targets");
        modelBuilder.Entity<DailyMedicationTargetItem>().ToTable("daily_medication_target_items");
        modelBuilder.Entity<PatientMedicationLog>().ToTable("patient_medication_logs");

        modelBuilder.Entity<User>().HasIndex(u => u.Email).IsUnique();
        modelBuilder.Entity<Patient>().HasQueryFilter(p => p.DeletedAt == null);
    }
}
