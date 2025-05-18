<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('perkembangan_anak', function (Blueprint $table) {
            $table->id();
            $table->foreignId('anak_id')->constrained('anak')->onDelete('cascade');
            $table->date('tanggal');
            $table->decimal('berat_badan', 5, 2); // 5 digits total, 2 decimal places
            $table->decimal('tinggi_badan', 5, 2); // 5 digits total, 2 decimal places
            $table->foreignId('updated_from_id')->nullable()->constrained('perkembangan_anak')->onDelete('set null');
            $table->boolean('is_updated')->default(false);
            $table->foreignId('updated_by_id')->nullable()->constrained('perkembangan_anak')->onDelete('set null');
            $table->timestamps();
            $table->softDeletes();

            // Indexes for better performance
            $table->index(['anak_id', 'tanggal']);
            $table->index('is_updated');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('perkembangan_anak');
    }
}; 