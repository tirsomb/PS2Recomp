#include "runtime/gs/gs_metal_backend.h"
#include "runtime/gs/gs_cpu_backend.h"

#import <Metal/Metal.h>

#include <cstdio>
#include <stdexcept>

struct GSMetalBackend::Impl
{
    id<MTLDevice> device = nil;
    id<MTLCommandQueue> queue = nil;
    std::unique_ptr<GSCpuBackend> fallback = std::make_unique<GSCpuBackend>();

    Impl()
    {
        device = MTLCreateSystemDefaultDevice();
        if (device)
            queue = [device newCommandQueue];
    }

    bool valid() const { return device != nil && queue != nil; }
};

GSMetalBackend::GSMetalBackend() : m_impl(std::make_unique<Impl>()) {}
GSMetalBackend::~GSMetalBackend() = default;

bool GSMetalBackend::IsSupported()
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    return device != nil;
}

void GSMetalBackend::Initialize(uint8_t *vram, uint32_t vramSize)
{
    if (!m_impl->valid())
        throw std::runtime_error("Metal device or command queue unavailable");
    std::fprintf(stderr, "[gs-metal] device: %s; staged CPU raster fallback active\n",
                 m_impl->device.name.UTF8String);
    m_impl->fallback->Initialize(vram, vramSize);
}

void GSMetalBackend::Reset() { m_impl->fallback->Reset(); }
void GSMetalBackend::Submit(const GSPrimitiveBatch &batch) { m_impl->fallback->Submit(batch); }
void GSMetalBackend::LoadClut(const GSTex0Reg &tex0, const GSTexClutReg &texclut) { m_impl->fallback->LoadClut(tex0, texclut); }
void GSMetalBackend::BeginTransfer(const GSTransferCommand &command) { m_impl->fallback->BeginTransfer(command); }
void GSMetalBackend::UploadImage(const uint8_t *data, uint32_t sizeBytes) { m_impl->fallback->UploadImage(data, sizeBytes); }
void GSMetalBackend::Flush() { m_impl->fallback->Flush(); }
void GSMetalBackend::TextureFlush() { m_impl->fallback->TextureFlush(); }
void GSMetalBackend::Sync(GSSyncReason reason) { m_impl->fallback->Sync(reason); }
PresentationFrame GSMetalBackend::Present(const GSPresentationRequest &request) { return m_impl->fallback->Present(request); }
bool GSMetalBackend::ClearFramebuffer(const GSContext &context, uint32_t rgba) { return m_impl->fallback->ClearFramebuffer(context, rgba); }
uint32_t GSMetalBackend::ConsumeLocalToHostBytes(uint8_t *dst, uint32_t maxBytes) { return m_impl->fallback->ConsumeLocalToHostBytes(dst, maxBytes); }
uint32_t GSMetalBackend::ReadVram(uint32_t psm, uint32_t base, uint32_t bw, uint32_t x, uint32_t y) const { return m_impl->fallback->ReadVram(psm, base, bw, x, y); }
void GSMetalBackend::WriteVram(uint32_t psm, uint32_t base, uint32_t bw, uint32_t x, uint32_t y, uint32_t value) { m_impl->fallback->WriteVram(psm, base, bw, x, y, value); }
void GSMetalBackend::SnapshotVram(std::vector<uint8_t> &out) const { m_impl->fallback->SnapshotVram(out); }
GSTransferSnapshot GSMetalBackend::GetTransferSnapshot() const { return m_impl->fallback->GetTransferSnapshot(); }
bool GSMetalBackend::ExportState(GSBackendState &out) { return m_impl->fallback->ExportState(out); }
bool GSMetalBackend::ImportState(const GSBackendState &state) { return m_impl->fallback->ImportState(state); }
