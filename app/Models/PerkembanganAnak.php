<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class PerkembanganAnak extends Model
{
    use SoftDeletes;

    protected $table = 'perkembangan_anak';
    
    protected $fillable = [
        'anak_id',
        'tanggal',
        'berat_badan',
        'tinggi_badan',
        'updated_from_id',
        'is_updated',
        'updated_by_id'
    ];

    protected $casts = [
        'tanggal' => 'datetime',
        'berat_badan' => 'decimal:2',
        'tinggi_badan' => 'decimal:2',
        'is_updated' => 'boolean'
    ];

    // Relationships
    public function anak()
    {
        return $this->belongsTo(Anak::class, 'anak_id');
    }

    public function oldRecord()
    {
        return $this->belongsTo(PerkembanganAnak::class, 'updated_from_id');
    }

    public function newRecord()
    {
        return $this->hasOne(PerkembanganAnak::class, 'updated_from_id');
    }

    // Validation rules
    public static function rules()
    {
        return [
            'anak_id' => 'required|exists:anak,id',
            'tanggal' => 'required|date',
            'berat_badan' => 'required|numeric|min:0',
            'tinggi_badan' => 'required|numeric|min:0',
        ];
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_updated', false);
    }

    public function scopeUpdated($query)
    {
        return $query->where('is_updated', true);
    }

    public function scopeLatest($query)
    {
        return $query->orderBy('tanggal', 'desc');
    }

    public function scopeOldest($query)
    {
        return $query->orderBy('tanggal', 'asc');
    }
} 