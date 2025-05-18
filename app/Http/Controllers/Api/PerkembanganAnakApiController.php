<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\PerkembanganAnak;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class PerkembanganAnakApiController extends Controller
{
    /**
     * Get all growth data for a child
     */
    public function getByAnakId($anakId)
    {
        try {
            $perkembangan = PerkembanganAnak::where('anak_id', $anakId)
                ->orderBy('tanggal', 'asc')
                ->get();

            return response()->json([
                'status' => 'success',
                'perkembangan' => $perkembangan,
                'child_info' => [
                    'id' => $anakId,
                    'records_count' => $perkembangan->count()
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to get growth data: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Store new growth data
     * Always creates a new record to maintain history
     */
    public function store(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'anak_id' => 'required|exists:anak,id',
                'tanggal' => 'required|date',
                'berat_badan' => 'required|numeric|min:0',
                'tinggi_badan' => 'required|numeric|min:0',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Create new record
            $perkembangan = PerkembanganAnak::create([
                'anak_id' => $request->anak_id,
                'tanggal' => $request->tanggal,
                'berat_badan' => $request->berat_badan,
                'tinggi_badan' => $request->tinggi_badan,
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Growth data saved successfully',
                'perkembangan' => $perkembangan
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to save growth data: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update existing growth data
     * Instead of updating, creates a new record and marks the old one as updated
     */
    public function update(Request $request, $id)
    {
        try {
            $validator = Validator::make($request->all(), [
                'anak_id' => 'required|exists:anak,id',
                'tanggal' => 'required|date',
                'berat_badan' => 'required|numeric|min:0',
                'tinggi_badan' => 'required|numeric|min:0',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Get the old record
            $oldRecord = PerkembanganAnak::findOrFail($id);
            
            // Create new record with updated data
            $newRecord = PerkembanganAnak::create([
                'anak_id' => $request->anak_id,
                'tanggal' => $request->tanggal,
                'berat_badan' => $request->berat_badan,
                'tinggi_badan' => $request->tinggi_badan,
                'updated_from_id' => $id, // Reference to the old record
            ]);

            // Mark old record as updated
            $oldRecord->update([
                'is_updated' => true,
                'updated_by_id' => $newRecord->id
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Growth data updated successfully',
                'perkembangan' => $newRecord,
                'old_record' => $oldRecord
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to update growth data: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete growth data
     */
    public function destroy($id)
    {
        try {
            $perkembangan = PerkembanganAnak::findOrFail($id);
            $perkembangan->delete();

            return response()->json([
                'status' => 'success',
                'message' => 'Growth data deleted successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to delete growth data: ' . $e->getMessage()
            ], 500);
        }
    }
} 