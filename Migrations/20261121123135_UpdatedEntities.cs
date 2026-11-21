using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace sutura_api.Migrations
{
    /// <inheritdoc />
    public partial class UpdatedEntities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_MeasurementsSet_Ateliers_AtelierId",
                table: "MeasurementsSet");

            migrationBuilder.DropIndex(
                name: "IX_MeasurementsSet_AtelierId",
                table: "MeasurementsSet");

            migrationBuilder.DropColumn(
                name: "DeletedAtUtc",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "ServerUpdatedAtUtc",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "DeletedAtUtc",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "ServerUpdatedAtUtc",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "DeletedAtUtc",
                table: "MeasurementsSet");

            migrationBuilder.DropColumn(
                name: "GarmentType",
                table: "MeasurementsSet");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "MeasurementsSet");

            migrationBuilder.DropColumn(
                name: "ServerUpdatedAtUtc",
                table: "MeasurementsSet");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "MeasurementsSet");

            migrationBuilder.DropColumn(
                name: "CreatedAtUtc",
                table: "Measurements");

            migrationBuilder.DropColumn(
                name: "DeletedAtUtc",
                table: "Measurements");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Measurements");

            migrationBuilder.DropColumn(
                name: "LastModifiedAtUtc",
                table: "Measurements");

            migrationBuilder.DropColumn(
                name: "ServerUpdatedAtUtc",
                table: "Measurements");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "Measurements");

            migrationBuilder.DropColumn(
                name: "CreatedAtUtc",
                table: "Garments");

            migrationBuilder.DropColumn(
                name: "DeletedAtUtc",
                table: "Garments");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Garments");

            migrationBuilder.DropColumn(
                name: "LastModifiedAtUtc",
                table: "Garments");

            migrationBuilder.DropColumn(
                name: "ServerUpdatedAtUtc",
                table: "Garments");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "Garments");

            migrationBuilder.DropColumn(
                name: "CreatedAtUtc",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "DeletedAtUtc",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "LastModifiedAtUtc",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "ServerUpdatedAtUtc",
                table: "Clients");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "Clients");

            migrationBuilder.RenameColumn(
                name: "LastModifiedAtUtc",
                table: "Payments",
                newName: "UpdatedAt");

            migrationBuilder.RenameColumn(
                name: "CreatedAtUtc",
                table: "Payments",
                newName: "CreatedAt");

            migrationBuilder.RenameColumn(
                name: "LastModifiedAtUtc",
                table: "Orders",
                newName: "UpdatedAt");

            migrationBuilder.RenameColumn(
                name: "CreatedAtUtc",
                table: "Orders",
                newName: "CreatedAt");

            migrationBuilder.RenameColumn(
                name: "LastModifiedAtUtc",
                table: "MeasurementsSet",
                newName: "UpdatedAt");

            migrationBuilder.RenameColumn(
                name: "CreatedAtUtc",
                table: "MeasurementsSet",
                newName: "CreatedAt");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "UpdatedAt",
                table: "Payments",
                newName: "LastModifiedAtUtc");

            migrationBuilder.RenameColumn(
                name: "CreatedAt",
                table: "Payments",
                newName: "CreatedAtUtc");

            migrationBuilder.RenameColumn(
                name: "UpdatedAt",
                table: "Orders",
                newName: "LastModifiedAtUtc");

            migrationBuilder.RenameColumn(
                name: "CreatedAt",
                table: "Orders",
                newName: "CreatedAtUtc");

            migrationBuilder.RenameColumn(
                name: "UpdatedAt",
                table: "MeasurementsSet",
                newName: "LastModifiedAtUtc");

            migrationBuilder.RenameColumn(
                name: "CreatedAt",
                table: "MeasurementsSet",
                newName: "CreatedAtUtc");

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "DeletedAtUtc",
                table: "Payments",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Payments",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "ServerUpdatedAtUtc",
                table: "Payments",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncVersion",
                table: "Payments",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "DeletedAtUtc",
                table: "Orders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Orders",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "ServerUpdatedAtUtc",
                table: "Orders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncVersion",
                table: "Orders",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "DeletedAtUtc",
                table: "MeasurementsSet",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "GarmentType",
                table: "MeasurementsSet",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "MeasurementsSet",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "ServerUpdatedAtUtc",
                table: "MeasurementsSet",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncVersion",
                table: "MeasurementsSet",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "CreatedAtUtc",
                table: "Measurements",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "DeletedAtUtc",
                table: "Measurements",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Measurements",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAtUtc",
                table: "Measurements",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "ServerUpdatedAtUtc",
                table: "Measurements",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncVersion",
                table: "Measurements",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "CreatedAtUtc",
                table: "Garments",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "DeletedAtUtc",
                table: "Garments",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Garments",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAtUtc",
                table: "Garments",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "ServerUpdatedAtUtc",
                table: "Garments",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncVersion",
                table: "Garments",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "CreatedAtUtc",
                table: "Clients",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "DeletedAtUtc",
                table: "Clients",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Clients",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAtUtc",
                table: "Clients",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "ServerUpdatedAtUtc",
                table: "Clients",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncVersion",
                table: "Clients",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_MeasurementsSet_AtelierId",
                table: "MeasurementsSet",
                column: "AtelierId");

            migrationBuilder.AddForeignKey(
                name: "FK_MeasurementsSet_Ateliers_AtelierId",
                table: "MeasurementsSet",
                column: "AtelierId",
                principalTable: "Ateliers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
