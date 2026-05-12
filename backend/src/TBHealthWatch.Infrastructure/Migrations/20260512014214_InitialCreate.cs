using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TBHealthWatch.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "regions",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "text", nullable: false),
                    code = table.Column<string>(type: "text", nullable: false),
                    kota = table.Column<string>(type: "text", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_regions", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "patients",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    nik = table.Column<string>(type: "text", nullable: true),
                    full_name = table.Column<string>(type: "text", nullable: false),
                    dob = table.Column<DateOnly>(type: "date", nullable: true),
                    gender = table.Column<char>(type: "char(1)", nullable: true),
                    phone = table.Column<string>(type: "text", nullable: true),
                    address = table.Column<string>(type: "text", nullable: true),
                    region_id = table.Column<Guid>(type: "uuid", nullable: true),
                    photo_url = table.Column<string>(type: "text", nullable: true),
                    registered_by_user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    registered_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    deleted_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_patients", x => x.id);
                    table.ForeignKey(
                        name: "fk_patients_regions_region_id",
                        column: x => x.region_id,
                        principalTable: "regions",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "users",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    email = table.Column<string>(type: "text", nullable: false),
                    password_hash = table.Column<string>(type: "text", nullable: false),
                    full_name = table.Column<string>(type: "text", nullable: false),
                    specialization = table.Column<string>(type: "text", nullable: true),
                    facility_name = table.Column<string>(type: "text", nullable: true),
                    facility_role = table.Column<string>(type: "text", nullable: true),
                    assignment_location = table.Column<string>(type: "text", nullable: true),
                    region_id = table.Column<Guid>(type: "uuid", nullable: true),
                    phone = table.Column<string>(type: "text", nullable: true),
                    address = table.Column<string>(type: "text", nullable: true),
                    avatar_url = table.Column<string>(type: "text", nullable: true),
                    is_verified = table.Column<bool>(type: "boolean", nullable: false),
                    last_login_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_users", x => x.id);
                    table.ForeignKey(
                        name: "fk_users_regions_region_id",
                        column: x => x.region_id,
                        principalTable: "regions",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "medication_adherence",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    patient_id = table.Column<Guid>(type: "uuid", nullable: false),
                    phase_1_start_date = table.Column<DateOnly>(type: "date", nullable: false),
                    phase_1_end_date = table.Column<DateOnly>(type: "date", nullable: false),
                    phase_2_start_date = table.Column<DateOnly>(type: "date", nullable: true),
                    phase_2_end_date = table.Column<DateOnly>(type: "date", nullable: true),
                    treatment_completed_date = table.Column<DateOnly>(type: "date", nullable: true),
                    status = table.Column<string>(type: "text", nullable: false),
                    notes = table.Column<string>(type: "text", nullable: true),
                    created_by_user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_medication_adherence", x => x.id);
                    table.ForeignKey(
                        name: "fk_medication_adherence_patients_patient_id",
                        column: x => x.patient_id,
                        principalTable: "patients",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "refresh_tokens",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    token_hash = table.Column<string>(type: "text", nullable: false),
                    expires_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    revoked_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_refresh_tokens", x => x.id);
                    table.ForeignKey(
                        name: "fk_refresh_tokens_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "adherence_logs",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    medication_adherence_id = table.Column<Guid>(type: "uuid", nullable: false),
                    log_date = table.Column<DateOnly>(type: "date", nullable: false),
                    phase = table.Column<string>(type: "text", nullable: false),
                    status = table.Column<string>(type: "text", nullable: false),
                    notes = table.Column<string>(type: "text", nullable: true),
                    recorded_by_user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_adherence_logs", x => x.id);
                    table.ForeignKey(
                        name: "fk_adherence_logs_medication_adherences_medication_adherence_id",
                        column: x => x.medication_adherence_id,
                        principalTable: "medication_adherence",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_adherence_logs_medication_adherence_id",
                table: "adherence_logs",
                column: "medication_adherence_id");

            migrationBuilder.CreateIndex(
                name: "ix_medication_adherence_patient_id",
                table: "medication_adherence",
                column: "patient_id");

            migrationBuilder.CreateIndex(
                name: "ix_patients_nik",
                table: "patients",
                column: "nik",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_patients_region_id",
                table: "patients",
                column: "region_id");

            migrationBuilder.CreateIndex(
                name: "ix_refresh_tokens_token_hash",
                table: "refresh_tokens",
                column: "token_hash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_refresh_tokens_user_id",
                table: "refresh_tokens",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "ix_users_email",
                table: "users",
                column: "email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_users_region_id",
                table: "users",
                column: "region_id");

            migrationBuilder.Sql(@"
CREATE OR REPLACE VIEW v_patient_current_status AS
SELECT
    p.id          AS patient_id,
    p.full_name,
    ma.id         AS medication_adherence_id,
    CASE
        WHEN ma.id IS NULL
            THEN 'Tidak Ada Pengobatan'
        WHEN ma.treatment_completed_date IS NOT NULL
             AND CURRENT_DATE >= ma.treatment_completed_date
            THEN 'Sembuh'
        WHEN CURRENT_DATE < ma.phase_1_end_date
            THEN 'Resiko Tinggi'
        WHEN CURRENT_DATE < (ma.phase_1_end_date + INTERVAL '4 months')
            THEN 'Dalam Perawatan'
        ELSE
          CASE ma.status
            WHEN 'completed'    THEN 'Selesai'
            WHEN 'discontinued' THEN 'Dihentikan'
            ELSE 'Perlu Evaluasi'
          END
    END AS status
FROM patients p
LEFT JOIN medication_adherence ma
    ON ma.patient_id = p.id AND ma.status = 'active'
WHERE p.deleted_at IS NULL;

CREATE OR REPLACE VIEW v_adherence_summary AS
SELECT
    ma.patient_id,
    ma.id                                                                       AS medication_adherence_id,
    al.phase,
    COUNT(al.id)                                                                AS total_logged_days,
    COUNT(al.id) FILTER (WHERE al.status = 'taken')                            AS taken_days,
    COUNT(al.id) FILTER (WHERE al.status = 'missed')                           AS missed_days,
    COUNT(al.id) FILTER (WHERE al.status = 'partial')                          AS partial_days,
    COUNT(al.id) FILTER (WHERE al.status = 'pending')                          AS pending_days,
    ROUND(
        COUNT(al.id) FILTER (WHERE al.status = 'taken')::NUMERIC /
        NULLIF(COUNT(al.id) FILTER (WHERE al.status != 'pending'), 0) * 100,
        2
    )                                                                           AS adherence_percentage
FROM medication_adherence ma
JOIN adherence_logs al ON al.medication_adherence_id = ma.id
GROUP BY ma.patient_id, ma.id, al.phase;
");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DROP VIEW IF EXISTS v_adherence_summary; DROP VIEW IF EXISTS v_patient_current_status;");

            migrationBuilder.DropTable(
                name: "adherence_logs");

            migrationBuilder.DropTable(
                name: "refresh_tokens");

            migrationBuilder.DropTable(
                name: "medication_adherence");

            migrationBuilder.DropTable(
                name: "users");

            migrationBuilder.DropTable(
                name: "patients");

            migrationBuilder.DropTable(
                name: "regions");
        }
    }
}
