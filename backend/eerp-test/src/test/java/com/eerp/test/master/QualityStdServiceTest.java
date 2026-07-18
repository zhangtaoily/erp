package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.master.entity.MdQualityStd;
import com.eerp.master.mapper.MdQualityStdMapper;
import com.eerp.master.service.QualityStdService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class QualityStdServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private MdQualityStdMapper mdQualityStdMapper;

    @InjectMocks private QualityStdService qualityStdService;

    private static final String BO_CODE = "MD_QUALITY_STD";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存质量标准：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = qualityStdService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存质量标准数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = qualityStdService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用质量标准：更新status=1")
    void testEnable() {
        MdQualityStd qualityStd = new MdQualityStd();
        qualityStd.setId(ID);
        qualityStd.setStatus(0);
        when(mdQualityStdMapper.selectById(ID)).thenReturn(qualityStd);

        qualityStdService.enable(ID);

        assertEquals(1, qualityStd.getStatus());
        verify(mdQualityStdMapper).updateById(qualityStd);
    }

    @Test
    @DisplayName("查询质量标准详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = qualityStdService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询质量标准：委托 Mapper")
    void testFindById() {
        MdQualityStd qualityStd = new MdQualityStd();
        qualityStd.setId(ID);
        when(mdQualityStdMapper.selectById(ID)).thenReturn(qualityStd);

        MdQualityStd result = qualityStdService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
