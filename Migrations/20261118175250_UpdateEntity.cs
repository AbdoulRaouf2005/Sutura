using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace sutura_api.Migrations
{
    /// <inheritdoc />
    public partial class UpdateEntity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Atelier_AspNetUsers_OwnerId",
                table: "Atelier");

            migrationBuilder.DropForeignKey(
                name: "FK_Clients_Atelier_AtelierId",
                table: "Clients");

            migrationBuilder.DropForeignKey(
                name: "FK_Garments_Atelier_AtelierId",
                table: "Garments");

            migrationBuilder.DropForeignKey(
                name: "FK_MeasurementsSet_Atelier_AtelierId",
                table: "MeasurementsSet");

            migrationBuilder.DropForeignKey(
                name: "FK_Orders_Atelier_AtelierId",
                table: "Orders");

            migrationBuilder.DropForeignKey(
                name: "FK_Payments_Atelier_AtelierId",
                table: "Payments");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Atelier",
                table: "Atelier");

            migrationBuilder.DropColumn(
                name: "ReplacedByTokenId",
                table: "RefreshTokens");

            migrationBuilder.DropColumn(
                name: "Address",
                table: "Atelier");

            migrationBuilder.DropColumn(
                name: "CreatedAtUtc",
                table: "Atelier");

            migrationBuilder.DropColumn(
                name: "Currency",
                table: "Atelier");

            migrationBuilder.DropColumn(
                name: "DeletedAtUtc",
                table: "Atelier");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Atelier");

            migrationBuilder.DropColumn(
                name: "Phone",
                table: "Atelier");

            migrationBuilder.DropColumn(
                name: "ServerUpdatedAtUtc",
                table: "Atelier");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "Atelier");

            migrationBuilder.RenameTable(
                name: "Atelier",
                newName: "Ateliers");

            migrationBuilder.RenameColumn(
                name: "LastModifiedAtUtc",
                table: "Ateliers",
                newName: "CreatedAt");

            migrationBuilder.RenameIndex(
                name: "IX_Atelier_OwnerId",
                table: "Ateliers",
                newName: "IX_Ateliers_OwnerId");

            migrationBuilder.AddColumn<string>(
                name: "ReplacedByTokenHash",
                table: "RefreshTokens",
                type: "text",
                nullable: true);

            migrationBuilder.AddPrimaryKey(
                name: "PK_Ateliers",
                table: "Ateliers",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Ateliers_AspNetUsers_OwnerId",
                table: "Ateliers",
                column: "OwnerId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Clients_Ateliers_AtelierId",
                table: "Clients",
                column: "AtelierId",
                principalTable: "Ateliers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Garments_Ateliers_AtelierId",
                table: "Garments",
                column: "AtelierId",
                principalTable: "Ateliers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_MeasurementsSet_Ateliers_AtelierId",
                table: "MeasurementsSet",
                column: "AtelierId",
                principalTable: "Ateliers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_Ateliers_AtelierId",
                table: "Orders",
                column: "AtelierId",
                principalTable: "Ateliers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Payments_Ateliers_AtelierId",
                table: "Payments",
                column: "AtelierId",
                principalTable: "Ateliers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Ateliers_AspNetUsers_OwnerId",
                table: "Ateliers");

            migrationBuilder.DropForeignKey(
                name: "FK_Clients_Ateliers_AtelierId",
                table: "Clients");

            migrationBuilder.DropForeignKey(
                name: "FK_Garments_Ateliers_AtelierId",
                table: "Garments");

            migrationBuilder.DropForeignKey(
                name: "FK_MeasurementsSet_Ateliers_AtelierId",
                table: "MeasurementsSet");

            migrationBuilder.DropForeignKey(
                name: "FK_Orders_Ateliers_AtelierId",
                table: "Orders");

            migrationBuilder.DropForeignKey(
                name: "FK_Payments_Ateliers_AtelierId",
                table: "Payments");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Ateliers",
                table: "Ateliers");

            migrationBuilder.DropColumn(
                name: "ReplacedByTokenHash",
                table: "RefreshTokens");

            migrationBuilder.RenameTable(
                name: "Ateliers",
                newName: "Atelier");

            migrationBuilder.RenameColumn(
                name: "CreatedAt",
                table: "Atelier",
                newName: "LastModifiedAtUtc");

            migrationBuilder.RenameIndex(
                name: "IX_Ateliers_OwnerId",
                table: "Atelier",
                newName: "IX_Atelier_OwnerId");

            migrationBuilder.AddColumn<Guid>(
                name: "ReplacedByTokenId",
                table: "RefreshTokens",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Address",
                table: "Atelier",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "CreatedAtUtc",
                table: "Atelier",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<string>(
                name: "Currency",
                table: "Atelier",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "DeletedAtUtc",
                table: "Atelier",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Atelier",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "Phone",
                table: "Atelier",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "ServerUpdatedAtUtc",
                table: "Atelier",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncVersion",
                table: "Atelier",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddPrimaryKey(
                name: "PK_Atelier",
                table: "Atelier",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Atelier_AspNetUsers_OwnerId",
                table: "Atelier",
                column: "OwnerId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Clients_Atelier_AtelierId",
                table: "Clients",
                column: "AtelierId",
                principalTable: "Atelier",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Garments_Atelier_AtelierId",
                table: "Garments",
                column: "AtelierId",
                principalTable: "Atelier",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_MeasurementsSet_Atelier_AtelierId",
                table: "MeasurementsSet",
                column: "AtelierId",
                principalTable: "Atelier",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_Atelier_AtelierId",
                table: "Orders",
                column: "AtelierId",
                principalTable: "Atelier",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Payments_Atelier_AtelierId",
                table: "Payments",
                column: "AtelierId",
                principalTable: "Atelier",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
